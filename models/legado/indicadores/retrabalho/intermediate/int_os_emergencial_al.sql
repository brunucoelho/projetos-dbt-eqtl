{{ config(
    materialized='table'
) }}

WITH ultima_atribuicao AS (
    SELECT
        ocorrencia_id,
        MAX(atribuicao_oc_id) AS atribuicao_oc_id
    FROM eqtlinfo_raw.oper_al.atribui_oc_emergencial
    GROUP BY ocorrencia_id
),
latitude_longitude AS (
    SELECT
        ua.ocorrencia_id,
        MAX(mr.latitude) AS latitude,
        MAX(mr.longitude) AS longitude
    FROM ultima_atribuicao ua
    LEFT JOIN eqtlinfo_raw.oper_al.atribui_oc_mensagem_retorno mr
        ON mr.atribuicao_oc_id = ua.atribuicao_oc_id
        AND mr.macro_id = 33
    GROUP BY ua.ocorrencia_id
)
SELECT
    'EQTL AL' AS empresa,
    CURRENT_TIMESTAMP AS data_carga,       
    oc.oco_data_conclusao,
    CAST(ll.latitude AS varchar) AS latitude,
    CAST(ll.longitude AS varchar) AS longitude,
    br.bai_nome AS bairro,
    CASE oc.tb_tp_abrangencia
        WHEN 'CR' THEN 'CONSUMIDOR'
        WHEN 'TF' THEN 'TRANSFORMADOR'
        WHEN 'CH' THEN 'CHAVE'
        WHEN 'AL' THEN 'ALIMENTADOR'
        WHEN 'SE' THEN 'SUBESTACAO'
        ELSE oc.tb_tp_abrangencia
    END AS abrangencia,
    oc.ocorrencia_id AS os_oper,
    oc.oco_ano || '-' || oc.oco_mes || '/' || oc.oco_numero AS os,
    'NR' AS ostipo,
    CASE
        WHEN oc.tb_tp_abrangencia IN ('CR', 'NI') THEN 'IND'
        ELSE 'COL'
    END AS ossubtipo,
    mp.mnc_nome AS municipio,
    lo.loc_nome AS localidade,
    TRUNC(oc.cr_numero, 0) AS uc,
    pt.prx_descricao AS prefixo,
    SUBSTR(oc.oco_observacoes_atendimento, 0, 250) AS registro_exec,
    com.tcd_def_descricao AS componente_danificado,
    com.tb_defeito_id,
    oc.tb_causa_id AS cod_conclusao,
    tc.tca_descricao AS tipo_conclusao,
    sub.tb_subcausa_id AS cod_subcausa,
    sub.tsc_descricao AS subcausa,
    CASE
        WHEN oc.tb_causa_id IN (
            2, 4, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 27,
            34, 39, 50, 56, 59, 73, 74, 89, 90, 92, 96, 98, 99, 100, 101,
            118, 148, 149, 150, 151, 252, 262, 273, 274, 276
        ) THEN 'I'
        ELSE 'P'
    END AS tipo,
    rg.rel_descricao AS regional,
    pa3.pap_nome AS base,
    oc.oco_data_nr AS data_origem
FROM eqtlinfo_raw.oper_al.ocorrencia oc
LEFT JOIN latitude_longitude ll 
    ON ll.ocorrencia_id = oc.ocorrencia_id
LEFT JOIN eqtlinfo_raw.oper_al.tipo_de_subcausa sub 
    ON sub.tb_subcausa_id = oc.tb_subcausa_id
INNER JOIN eqtlinfo_raw.oper_al.tipo_de_causa tc 
    ON tc.tb_causa_id = oc.tb_causa_id
INNER JOIN eqtlinfo_raw.oper_al.historico_ocorrencia_turma ot 
    ON ot.ocorrencia_id = oc.ocorrencia_id
INNER JOIN eqtlinfo_raw.oper_al.historico_turma_plantao tp 
    ON tp.hist_turma_plantao_id = ot.hist_turma_plantao_id
INNER JOIN eqtlinfo_raw.oper_al.prefixo_turma pt 
    ON pt.prefixo_turma_id = tp.prefixo_turma_id
INNER JOIN eqtlinfo_raw.oper_al.base bs 
    ON bs.base_id = oc.base_id
INNER JOIN eqtlinfo_raw.oper_al.ponto_apoio pa 
    ON pa.codigo_pa = bs.codigo_pa
INNER JOIN eqtlinfo_raw.oper_al.unidade_territorial ut 
    ON ut.reg_eletrica_id = pa.reg_eletrica_id
INNER JOIN eqtlinfo_raw.oper_al.regiao_eletrica rg 
    ON rg.reg_eletrica_id = pa.reg_eletrica_id
INNER JOIN eqtlinfo_raw.oper_al.bairro br 
    ON br.bairro_id = oc.bairro_id
INNER JOIN eqtlinfo_raw.oper_al.localidade lo 
    ON lo.lc_id = br.lc_id
INNER JOIN eqtlinfo_raw.oper_al.municipio mp 
    ON mp.mnc_id = lo.mnc_id
LEFT JOIN eqtlinfo_raw.oper_al.base bs3 
    ON bs3.base_id = mp.base_id
INNER JOIN eqtlinfo_raw.oper_al.ponto_apoio pa3 
    ON pa3.codigo_pa = bs.codigo_pa
LEFT JOIN eqtlinfo_raw.oper_al.code_medida t 
    ON t.cdm_id = oc.tipo_conclusao
LEFT JOIN eqtlinfo_raw.oper_al.tipo_de_componente_danificado com 
    ON com.tb_defeito_id = oc.tb_defeito_id
LEFT JOIN eqtlinfo_raw.oper_al.instalacao_operacao io 
    ON oc.instalacao_id = io.instalacao_id
WHERE
    oc.oco_status = 'F'
    AND ot.hot_vi_status = 4
    AND oc.oco_data_conclusao >= TO_DATE('01/01/2023', 'DD/MM/YYYY') - 90
    AND pt.prx_descricao NOT IN ('OFS001','MAN001','MAN002','MAN003','MAN004','MAN006','MAN008','MAN010','MAN015','MAN016','MAN017','MAN018','MAN019','MAN020','MAN023','MAN026','MAN027','MAN028','MAN029','MAN036','MAN037','MAN038','MAN043','MAN044')