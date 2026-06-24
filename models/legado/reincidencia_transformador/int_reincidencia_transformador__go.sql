{{config(
    materialized='table'
)}}

WITH EquipeUltima AS (
    SELECT 
        ot.ocorrencia_id,
        pt.PRX_DESCRICAO AS equipe,
        ROW_NUMBER() OVER (
            PARTITION BY ot.ocorrencia_id 
            ORDER BY ot.hist_ocorrencia_turma_id DESC
        ) AS rn
    FROM EQTLINFO_RAW.OPER_GO.historico_ocorrencia_turma ot
    JOIN EQTLINFO_RAW.OPER_GO.historico_turma_plantao tp 
         ON tp.hist_turma_plantao_id = ot.hist_turma_plantao_id
    JOIN EQTLINFO_RAW.OPER_GO.prefixo_turma pt 
         ON pt.prefixo_turma_id = tp.prefixo_turma_id
),
OcorrenciasComJanela AS (
    SELECT 
        oc.oco_data_nr,
        ip.iop_num,
        tc.TCA_DESCRICAO,
        ROW_NUMBER() OVER (
            PARTITION BY ip.iop_num, tc.TCA_DESCRICAO 
            ORDER BY oc.oco_data_nr
        ) AS rn_ptp,
        SUM(CASE WHEN tc.TCA_DESCRICAO NOT ILIKE ('%PTP%') THEN 1 ELSE 0 END) OVER (
            PARTITION BY ip.iop_num 
            ORDER BY oc.oco_data_nr 
            RANGE BETWEEN INTERVAL '90 DAY' PRECEDING AND CURRENT ROW
        ) AS reinc_count_geral,
        SUM(CASE WHEN tc.TCA_DESCRICAO ILIKE ('%PTP%') THEN 1 ELSE 0 END) OVER (
            PARTITION BY ip.iop_num 
            ORDER BY oc.oco_data_nr 
            RANGE BETWEEN INTERVAL '90 DAY' PRECEDING AND CURRENT ROW
        ) AS reinc_count_ptp,
        oc.ocorrencia_id,
        oc.instalacao_id,
        oc.oco_data_conclusao,
        eq.equipe
    FROM EQTLINFO_RAW.OPER_GO.ocorrencia oc
    LEFT JOIN EQTLINFO_RAW.OPER_GO.INSTALACAO_PERMANENTE ip 
           ON oc.instalacao_id = ip.instalacao_id
    LEFT JOIN EQTLINFO_RAW.OPER_GO.tipo_de_causa tc 
           ON tc.tb_causa_id = oc.tb_causa_id
    LEFT JOIN EquipeUltima eq 
           ON eq.ocorrencia_id = oc.ocorrencia_id AND eq.rn = 1
    WHERE 
        oc.TB_NATUREZA_ID = 1
        AND oc.OCO_INTERRUPCAO = 'S'),


/* =================================================== */
/*     OCORRÊNCIA ANTERIOR REAL (90 DIAS) – CORRIGIDO   */
/* =================================================== */
OcorrenciaAnterior90dias AS (
    SELECT 
        cur.ocorrencia_id AS ocorrencia_atual,
        prev.ocorrencia_id AS ocorrencia_anterior,
        REGEXP_REPLACE(TO_CHAR(prev.OCO_ANO),'\\.0+$', '')
        ||'-'||
        REGEXP_REPLACE(TO_CHAR(prev.OCO_MES),'\\.0+$', '')
        ||'-'||
        REGEXP_REPLACE(TO_CHAR(prev.OCO_NUMERO),'\\.0+$', '') ocorrencia,
        prev.tb_causa_id AS causa_anterior_id,
        eq_prev.equipe AS equipe_anterior,
        prev.oco_data_nr AS data_anterior,

        ROW_NUMBER() OVER (
            PARTITION BY cur.ocorrencia_id
            ORDER BY prev.oco_data_nr DESC
        ) AS rn

    FROM EQTLINFO_RAW.OPER_GO.ocorrencia cur
    JOIN EQTLINFO_RAW.OPER_GO.ocorrencia prev
         ON prev.instalacao_id = cur.instalacao_id
        AND prev.oco_data_nr < cur.oco_data_nr
        AND prev.oco_data_nr >= cur.oco_data_nr - INTERVAL '90 DAY'
    LEFT JOIN EquipeUltima eq_prev
         ON eq_prev.ocorrencia_id = prev.ocorrencia_id
        AND eq_prev.rn = 1
    WHERE 
        cur.TB_NATUREZA_ID = 1
        AND cur.OCO_INTERRUPCAO = 'S'
),

DADOS_BRUTOS AS (
    SELECT 
        'EQTL GO' AS Empresa,
        ' ' || TO_CHAR(CURRENT_TIMESTAMP,'DD/MM/YYYY HH24:MI') AS data_carga,
        rg.rel_descricao AS regional,
        pa.pap_nome AS SECCIONAL,
        oc.oco_data_nr AS DATA,
        rc.equipe AS PRX_DESCRICAO,
        oc.oco_data_conclusao AS data_conclusao,
        TN.TNA_DESCRICAO AS NATUREZA,
        ip.IOP_LOCALIZACAO AS PERIMETRO,
        TO_CHAR(oc.oco_numero) AS oco_numero,
        -- Calcula a ocorrência uma vez aqui
        REGEXP_REPLACE(TO_CHAR(oc.OCO_ANO), '\\.0+$', '')
            ||'-'|| REGEXP_REPLACE(TO_CHAR(oc.OCO_MES), '\\.0+$', '')
            ||'-'|| REGEXP_REPLACE(TO_CHAR(oc.OCO_NUMERO), '\\.0+$', '') AS ocorrencia,
        tc.TCA_DESCRICAO AS causa,
        oa.ocorrencia ocorrencia_anterior,
        tc_prev.TCA_DESCRICAO AS causa_anterior,
        oa.equipe_anterior,
        oc.tb_tp_abrangencia AS abrangencia,
        ip.iop_num AS PDF,
        DECODE(oc.tb_tp_abrangencia, 
            'CR', 'CONSUMIDOR', 'TF', 'TRANSFORMADOR', 
            'CH', 'CHAVE', 'AL', 'ALIMENTADOR', 
            'SE', 'SUBESTACAO', oc.tb_tp_abrangencia
        ) AS TIPO_EQP,
        con.cr_numero,
        ip.iop_kvan AS potencia,
        CASE
            WHEN tc.TCA_DESCRICAO ILIKE '%PTP%' AND rc.reinc_count_ptp >= 2 THEN 'S'
            WHEN tc.TCA_DESCRICAO ILIKE '%PTP%' AND rc.reinc_count_ptp = 1  THEN 'N'
            WHEN tc.TCA_DESCRICAO NOT ILIKE '%PTP%' AND rc.reinc_count_geral >= 2 THEN 'S'
            ELSE 'N'
        END AS reincidente_90_dias,
        CASE 
            WHEN rc.reinc_count_ptp < 2 THEN rc.reinc_count_geral 
            ELSE rc.reinc_count_ptp + rc.reinc_count_geral
        END AS n_reinc
    FROM EQTLINFO_RAW.OPER_GO.ocorrencia oc
    LEFT JOIN EQTLINFO_RAW.OPER_GO.TIPO_DE_NATUREZA TN     ON TN.TB_NATUREZA_ID = oc.TB_NATUREZA_ID
    LEFT JOIN EQTLINFO_RAW.OPER_GO.tipo_de_causa tc        ON tc.tb_causa_id = oc.tb_causa_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.base bs                ON bs.base_id = oc.base_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.ponto_apoio pa         ON pa.codigo_pa = bs.codigo_pa
    INNER JOIN EQTLINFO_RAW.OPER_GO.unidade_territorial ut ON ut.reg_eletrica_id = pa.reg_eletrica_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.regiao_eletrica rg     ON rg.reg_eletrica_id = pa.reg_eletrica_id
    JOIN EQTLINFO_RAW.OPER_GO.consumidor con               ON con.INSTALACAO_ID = oc.INSTALACAO_ID
    LEFT JOIN EQTLINFO_PRD.EQTL_GO.TAB_CADASTRO tb
        ON TO_DECIMAL(CON.CR_NUMERO) = REPLACE(LTRIM(TB.CONTA_CONTRATO,'0'),'X','0')
        AND TB.STATUS_INSTALACAO = 'ATIVA'
    LEFT JOIN EQTLINFO_RAW.OPER_GO.INSTALACAO_PERMANENTE ip ON oc.instalacao_id = ip.instalacao_id
    LEFT JOIN OcorrenciasComJanela rc                       ON rc.ocorrencia_id = oc.ocorrencia_id
    LEFT JOIN OcorrenciaAnterior90dias oa                   ON oa.ocorrencia_atual = oc.ocorrencia_id AND oa.rn = 1
    LEFT JOIN EQTLINFO_RAW.OPER_GO.tipo_de_causa tc_prev   ON tc_prev.tb_causa_id = oa.causa_anterior_id
    WHERE
        oc.oco_status = 'F'
        AND oc.oco_data_conclusao >= '2023-10-01'
        AND oc.TB_NATUREZA_ID = 1
        AND oc.OCO_INTERRUPCAO = 'S'
        AND pa.pap_nome NOT LIKE '%APOIO%'
        AND oc.tb_tp_abrangencia = 'TF'
)

SELECT
    Empresa, data_carga, regional, SECCIONAL, DATA, PRX_DESCRICAO,
    data_conclusao, NATUREZA, PERIMETRO, oco_numero, ocorrencia,
    causa, ocorrencia_anterior, causa_anterior, equipe_anterior,
    abrangencia, PDF, TIPO_EQP, potencia,
    reincidente_90_dias, n_reinc,
    COUNT(DISTINCT cr_numero) AS CLIE
FROM DADOS_BRUTOS
GROUP BY ALL