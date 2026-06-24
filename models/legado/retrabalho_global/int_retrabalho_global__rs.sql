/* =========================================================
   RETRABALHO GLOBAL - VERSÃO BLINDADA SNOWFLAKE
   ========================================================= */

{{config(
    materialized='table'
)}}

WITH BASE_EMERGENCIAL AS (

        SELECT
    'RIO GRANDE DO SUL' AS Empresa,
    'A' AS atros_status,
    oc.oco_data_nr AS data_origem,
    oc.oco_data_nr AS data_abertura,
    CURRENT_TIMESTAMP AS data_carga,      
    oc.oco_data_acionamento,    
    oc.oco_data_aceite AS inicio_deslocamento,    
    oc.oco_data_chegada,    
    oc.oco_data_conclusao,
    DATEDIFF('hour', oc.oco_data_nr, oc.oco_data_aceite) AS tmp,
    DATEDIFF('hour', oc.oco_data_aceite, oc.oco_data_chegada) AS tmd,
    DATEDIFF('hour', oc.oco_data_chegada, oc.oco_data_conclusao) AS tma,
    DATEDIFF('hour', oc.oco_data_nr, oc.oco_data_aceite) + DATEDIFF('hour', oc.oco_data_aceite, oc.oco_data_chegada) + DATEDIFF('hour', oc.oco_data_chegada, oc.oco_data_conclusao) AS tmat,     
    br.bai_nome AS bairro,
    'NR' AS tipo_ss,
    DECODE(oc.tb_tp_abrangencia, 'CR', 'CONSUMIDOR', 'TF', 'TRANSFORMADOR', 'CH', 'CHAVE', 'AL', 'ALIMENTADOR', 'SE', 'SUBESTACAO', oc.tb_tp_abrangencia) AS abrangencia,

    RTRIM(oc.oco_numero,'.00') || '-' ||
    RTRIM(oc.oco_mes,'.00') || '-' ||
    RTRIM(oc.oco_ano,'.00') AS os_oper,

    RTRIM(oc.oco_numero,'.00') || '-' ||
    RTRIM(oc.oco_mes,'.00') || '-' ||
    RTRIM(oc.oco_ano,'.00') AS os,

    'NR' AS ostipo,
    CASE
        WHEN oc.tb_tp_abrangencia = 'CR' THEN 'IND'
        WHEN oc.tb_tp_abrangencia = 'NI' THEN 'IND'
        ELSE 'COL'
    END AS ossubtipo,
rg.rel_descricao AS regional,
    pa.pap_nome AS SECCIONAL,
    mp.mnc_nome AS municipio,
    lo.loc_nome AS localidade,
    bs.bas_endereco base,
    TRUNC(oc.cr_numero, 0) AS uc,
    {{ normalize_prefix_model('pt.prx_descricao',"'RS'") }} AS prefixo,
    oc.oco_observacoes_atendimento AS registro_exec,    
    RTRIM(TO_CHAR(oc.tb_causa_id),'.00') AS cod_conclusao,
    tc.tca_descricao AS tipo_conclusao,
    sub.TB_SUBCAUSA_ID Cod_Subcausa,
            sub.tsc_descricao subcausa,
CASE
        WHEN oc.tb_tp_abrangencia IS NULL OR oc.tb_causa_id IS NULL THEN '?'
       WHEN oc.tb_causa_id IN (252, 262,273, 274, 276,287,289) THEN 'I'  
        ELSE 'P'
    END AS tipo,
    OC.TB_NATUREZA_ID
  
 FROM
    EQTLINFO_RAW.OPER_RS.ocorrencia oc
left JOIN  EQTLINFO_RAW.OPER_RS.tipo_de_subcausa sub on sub.tb_subcausa_id = oc.tb_subcausa_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.tipo_de_causa tc ON tc.tb_causa_id = oc.tb_causa_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.historico_ocorrencia_turma ot ON ot.ocorrencia_id = oc.ocorrencia_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.historico_turma_plantao tp ON tp.hist_turma_plantao_id = ot.hist_turma_plantao_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.prefixo_turma pt ON pt.prefixo_turma_id = tp.prefixo_turma_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.base bs ON bs.base_id = oc.base_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.ponto_apoio pa ON pa.codigo_pa = bs.codigo_pa
    --INNER JOIN EQTLINFO_RAW.OPER_RS.unidade_territorial ut ON ut.reg_eletrica_id = pa.reg_eletrica_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.regiao_eletrica rg ON rg.reg_eletrica_id = pa.reg_eletrica_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.bairro br ON br.bairro_id = oc.bairro_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.localidade lo ON lo.lc_id = br.lc_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.municipio mp ON mp.mnc_id = lo.mnc_id
WHERE
    oc.oco_status = 'F'
    AND ot.hot_vi_status = 4
    AND oc.oco_data_conclusao >= TO_DATE('01/10/2023', 'DD/MM/YYYY')
       --AND date_trunc('month',oc.OCO_DATA_NR) = '2025-01-01'::date
       --AND tc.tca_descricao NOT LIKE '%PTP%'      
       AND OC.TB_NATUREZA_ID = 5
        AND pa.codigo_pa < 10
AND oc.tb_tp_abrangencia = 'CR'
AND TIPO = 'P'
AND PREFIXO  NOT ILIKE ('%-H0%')
AND PREFIXO  NOT ILIKE ('%OFS%')
AND PREFIXO  NOT ILIKE ('%VIR-%')
),

BASE_COMERCIAL AS (

    WITH latest_atribui_os_comercial AS (
    SELECT
        ac2.cd_movto_os_comercial,
        MAX(ac2.atribuicao_os_id) AS max_atribuicao_os_id
    FROM
        EQTLINFO_RAW.OPER_RS.atribui_os_comercial ac2
    GROUP BY
        ac2.cd_movto_os_comercial
)
SELECT
    'RIO GRANDE DO SUL' AS Empresa,
    ac.atros_status,
    os.dt_solicitacao AS data_origem,
    os.dt_programacao_os AS data_abertura,    
    CURRENT_TIMESTAMP AS data_carga,       
    ac.atros_data AS oco_data_acionamento,    
    tc.host_vi_dt_ini_deslocamento AS inicio_deslocamento,    
    tc.host_vi_dt_fim_deslocamento AS oco_data_chegada,    
    cc.dt_conclusao AS oco_data_conclusao,     
    DATEDIFF('hour', os.dt_programacao_os,tc.host_vi_dt_ini_deslocamento) AS tmp,
    DATEDIFF('hour', tc.host_vi_dt_ini_deslocamento,tc.host_vi_dt_fim_deslocamento) AS tmd,
    DATEDIFF('hour', tc.host_vi_dt_ini_servico,tc.host_vi_dt_fim_servico) AS tma,
    DATEDIFF('hour', os.dt_programacao_os,tc.host_vi_dt_ini_deslocamento) + DATEDIFF('hour', tc.host_vi_dt_ini_deslocamento,tc.host_vi_dt_fim_deslocamento) + DATEDIFF('hour', tc.host_vi_dt_ini_servico,tc.host_vi_dt_fim_servico) AS tmat,
    br.bai_nome AS bairro,
    os.sstipo_id AS tipo_ss,
    'OS_COMERCIAL' AS abrangencia,
    REGEXP_REPLACE(TO_VARCHAR(os.nr_os),'\\.0+$', '') AS os_oper,
    TO_VARCHAR(os.cd_movto_os_comercial) AS os,
    os.ostipo_id AS ostipo,
    os.ossubtipo_id AS ossubtipo,
    rg.rel_descricao AS regional,
    pa.pap_nome AS SECCIONAL,
    mp.mnc_nome AS municipio,
    lo.loc_nome AS localidade,    
    bs.bas_endereco base,
    TRUNC(os.nr_uc, 0) AS uc,
    {{ normalize_prefix_model('PT.PRX_DESCRICAO',"'RS'") }} AS prefixo,     
    cc.ds_registro_atendimento AS registro_exec,    
    CASE
        WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NOT NULL THEN cc.cd_tp_conclusao_os
        ELSE cc.cd_tp_conclusao_os
    END AS cod_conclusao,
    CASE
        WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NOT NULL THEN cm.descricao
        --WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0001' THEN lrel.lcrelig_descricao
        WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NULL THEN cm.descricao
        WHEN cc.cd_tp_conclusao_os = '999' THEN 'RECUSA DE SERVIÇO'
        WHEN atros_status = 'C' AND cc.dt_conclusao IS NULL THEN 'SOBRAS'
        ELSE cm.descricao
    END AS tipo_conclusao,
    2000 AS Cod_Subcausa,
    'Comercial' AS subcausa,
    CASE
        WHEN cm.descricao ILIKE '%EXECUTADO%'
        OR cm.descricao ILIKE '%EXECUÇÃO%'
        OR cm.descricao IN ('EXEC.T. PAD. S/ TROCA  MED. E FIN. DE PAD.','APROVADO E LIGADO', 'MEDIDOR INSTALADO','PROCEDENTE','RELIGADO SIMBOLICO','EXEC.T. PAD.C/ TROCA  MED. E FIN. DE PAD.'	) THEN 'P'
        ELSE 'I'
    END AS tipo,
    NULL AS TB_NATUREZA_ID
      
FROM
    EQTLINFO_RAW.OPER_RS.movto_os_comercial os
    INNER JOIN EQTLINFO_RAW.OPER_RS.bairro br ON br.bairro_id = os.cd_bairro
    INNER JOIN EQTLINFO_RAW.OPER_RS.localidade lo ON lo.lc_id = br.lc_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.municipio mp ON mp.mnc_id = lo.mnc_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.conclui_os_comercial cc ON cc.cd_movto_os_comercial = os.cd_movto_os_comercial
    LEFT JOIN EQTLINFO_RAW.OPER_RS.tipo_ocorrencia_corte oc ON oc.tpoco_corte_id = cc.cd_tp_ocorrencia_corte
    INNER JOIN EQTLINFO_RAW.OPER_RS.atribui_os_comercial ac ON ac.cd_movto_os_comercial = os.cd_movto_os_comercial
    INNER JOIN EQTLINFO_RAW.OPER_RS.prefixo_turma pt ON pt.prefixo_turma_id = ac.prefixo_turma_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.turma_os_comercial tc ON tc.atribuicao_os_id = ac.atribuicao_os_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.base bs ON bs.base_id = br.base_id
    INNER JOIN EQTLINFO_RAW.OPER_RS.ponto_apoio pa ON pa.codigo_pa = bs.codigo_pa
    INNER JOIN EQTLINFO_RAW.OPER_RS.regiao_eletrica rg ON rg.reg_eletrica_id = pa.reg_eletrica_id    
    INNER JOIN EQTLINFO_RAW.OPER_RS.code_medida cm ON cm.ossubtipo_id = os.ossubtipo_id AND cc.cd_tp_conclusao_os = cm.code_medida_id    
    LEFT JOIN latest_atribui_os_comercial laoc ON laoc.cd_movto_os_comercial = ac.cd_movto_os_comercial AND laoc.max_atribuicao_os_id = ac.atribuicao_os_id
QUALIFY
    ROW_NUMBER() OVER (PARTITION BY os.cd_movto_os_comercial ORDER BY cm.tipo_conclusao) = 1
   -- AND tipo = 'P'
    AND  os.dt_programacao_os >= to_date('01/10/2023','DD/MM/YYYY')
    AND os.ostipo_id NOT IN ('CT','DS','NT','PA')  
    AND pt.prx_descricao NOT ILIKE ('%VIR-%')
    AND pt.prx_descricao NOT ILIKE ('%-H0%')
    AND pt.prx_descricao NOT ILIKE ('%OFS%')

 AND TIPO = 'P'
),
BASE_PERDAS AS(
SELECT 
'RIO GRANDE DO SUL' AS EMPRESA,
'A' AS ATROS_STATUS,
GPA.DATA_NOTA AS  DATA_ORIGEM,
GPA.DATA_NOTA AS DATA_ABERTURA,
GPA.DATA_CARGA AS DATA_CARGA,
NULL AS OCO_DATA_ACIONAMENTO,
NULL AS INICIO_DESLOCAMENTO,
NULL AS OCO_DATA_CHEGADA,
DATA_EXECUCAO AS OCO_DATA_CONCLUSAO,
NULL AS TMP,
NULL AS TMD,
NULL AS TMA,
NULL AS TMAT,
NULL AS BAIRRO,
GPA.CODIFICACAO AS TIPO_SS,
'COMERCIAL'ABRANGENCIA,
LTRIM(TO_VARCHAR(NOTA),'0') AS OS_OPER,
LTRIM(TO_VARCHAR(GPA.NOTA),'0') AS OS,
TIPO_NOTA AS OSTIPO,
GPA.CODIFICACAO AS OSSUBTIPO,
CASE	
	WHEN gpa.POLO IN ('FLORIANO','SAO RAIMUNDO NONATO','BOM JESUS') THEN 'FLORIANO'
	WHEN gpa.POLO IN ('PICOS','OEIRAS') THEN 'PICOS'
	WHEN gpa.POLO IN ('TERESINA','UNIAO','SAO PEDRO','CAMPO MAIOR') THEN 'METROPOLITANA'
	WHEN gpa.POLO IN ('PARNAIBA','PIRIPIRI') THEN 'PARNAIBA'
END REGIONAL,
GPA.POLO AS SECCIONAL,
GPA.MUNICIPIO AS municipio,
GPA.LOCALIDADE AS LOCALIDADE,
NULL AS BASE,
TRUNC(GPA.INSTALACAO,0) AS UC,
{{ normalize_prefix_model('NR_VIATURA',"'RS'") }} AS PREFIXO,
NULL AS REGISTRO_EXEC,
IRREGULARIDADE COD_CONCLUSAO,
CLASSIFICACAO_IRREG AS TIPO_CONCLUSAO,
NULL COD_SUBCAUSA,
NULL AS SUBCAUSA,
'P'TIPO,
NULL AS TB_NATUREZA_ID

   FROM EQTLINFO_PRD.GESTINFO_CORP.GIFC_plano_acoes GPA
WHERE UF = 'RS'
AND NORMALIZACAO = 1
AND DATA_NOTA >= '2023-10-01'

),
BASE_GERAL AS (
    SELECT * FROM BASE_EMERGENCIAL
    UNION ALL
    SELECT * FROM BASE_COMERCIAL
    UNION ALL 
    SELECT * FROM BASE_PERDAS
),
RECLAMACOES AS (
    SELECT *
    FROM BASE_EMERGENCIAL
    WHERE tb_natureza_id = 5
)

SELECT

    /* =====================================================
       EVENTO ATUAL (RECLAMAÇÃO EMERGENCIAL)
       ===================================================== */
r.data_carga,	
r.EMPRESA,
	r.uc,
	r.regional,
    r.SECCIONAL,
    r.municipio,
    r.localidade,
    r.base,
    r.bairro,
    r.DATA_ORIGEM,
    r.OCO_DATA_CONCLUSAO,
    r.OS_OPER,
    r.OS,
    r.OSTIPO,
    r.PREFIXO,
    r.TIPO_CONCLUSAO,
    r.SUBCAUSA,
    r.TIPO,
    r.registro_exec,

    /* =====================================================
       ORIGEM DO RETRABALHO (OS ANTERIOR)
       ===================================================== */

    s.DATA_ORIGEM           AS DATA_ORIGEM_ORIGEM,
    s.OCO_DATA_CONCLUSAO    AS OCO_DATA_CONCLUSAO_ORIGEM,
    s.OS_OPER               AS OS_OPER_ORIGEM,
    s.OS                    AS OS_ORIGEM,
    s.OSTIPO                AS OSTIPO_ORIGEM,
    S.OSSUBTIPO             AS OSSUBTIPO_ORIGEM, 
    s.PREFIXO               AS PREFIXO_ORIGEM,
    s.TIPO_CONCLUSAO        AS TIPO_CONCLUSAO_ORIGEM,
    s.SUBCAUSA              AS SUBCAUSA_ORIGEM,
    s.TIPO                  AS TIPO_ORIGEM,

    /* =====================================================
       MÉTRICA
       ===================================================== */

    DATEDIFF(
        'day',
        s.OCO_DATA_CONCLUSAO,
        r.DATA_ORIGEM
    ) AS DIAS_ENTRE,

    CASE
        WHEN s.OS_OPER IS NOT NULL THEN 1
        ELSE 0
    END AS FLAG_RETRABALHO,
    REGEXP_REPLACE(
    regexP_replace(r.PREFIXO, '^(AL_AL-|AP_AP-|GO_GO-|MA_MA-|PA_PA-|PI_PI-|RS_RS-|AL_|AP_|GO_|MA_|PA_|PI_|RS_|AL-|AP-|GO-|MA-|PA-|PI-|RS-)', '')
    ,'[^A-Z0-9]', '') PREFIXO_UNICO

FROM RECLAMACOES r

LEFT JOIN BASE_GERAL s
    ON r.UC = s.UC
    AND r.DATA_ORIGEM > s.OCO_DATA_CONCLUSAO
    AND DATEDIFF('day', s.OCO_DATA_CONCLUSAO, r.DATA_ORIGEM) BETWEEN 0 AND 90

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY r.OS_OPER
    ORDER BY s.OCO_DATA_CONCLUSAO DESC NULLS LAST
) = 1