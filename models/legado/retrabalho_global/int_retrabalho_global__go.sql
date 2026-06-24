/* =========================================================
   RETRABALHO GLOBAL - VERSÃO BLINDADA SNOWFLAKE
   ========================================================= */

{{config(
    materialized='table'
)}}

WITH BASE_EMERGENCIAL AS (

        SELECT
    'GOIAS' AS Empresa,
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
    TO_VARCHAR(oc.ocorrencia_id::integer) AS os_oper,
    RTRIM(oc.oco_ano,'.00') || '-' || RTRIM(oc.oco_mes,'.00') || '-' || RTRIM(oc.oco_numero,'.00') AS os,
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
    bs.bas_nome base,
    
    TRUNC(oc.cr_numero, 0) AS uc,
    {{ normalize_prefix_model('PT.PRX_DESCRICAO',"'GO'") }} AS prefixo,
    oc.oco_observacoes_atendimento AS registro_exec,    
    RTRIM(TO_CHAR(oc.tb_causa_id),'.00') AS cod_conclusao,
    tc.tca_descricao AS tipo_conclusao,
   NULL AS Cod_Subcausa,
   NULL AS subcausa,
CASE
        WHEN oc.tb_tp_abrangencia IS NULL OR oc.tb_causa_id IS NULL THEN '?'
       WHEN oc.tb_causa_id IN (11,12,13,14,22,23,34,39,54,56,65,82,83,84,85) THEN 'I'  
        ELSE 'P'
    END AS tipo,
    OC.TB_NATUREZA_ID
  
 FROM
    EQTLINFO_RAW.OPER_GO.ocorrencia oc
--  left JOIN  EQTLINFO_RAW.OPER_GO.tipo_de_subcausa sub on sub.tb_subcausa_id = oc.tb_subcausa_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.tipo_de_causa tc ON tc.tb_causa_id = oc.tb_causa_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.historico_ocorrencia_turma ot ON ot.ocorrencia_id = oc.ocorrencia_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.historico_turma_plantao tp ON tp.hist_turma_plantao_id = ot.hist_turma_plantao_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.prefixo_turma pt ON pt.prefixo_turma_id = tp.prefixo_turma_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.bairro br ON br.bairro_id = oc.bairro_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.localidade lo ON lo.lc_id = br.lc_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.municipio mp ON mp.mnc_id = lo.mnc_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.base bs ON bs.base_id = oc.base_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.ponto_apoio pa ON pa.codigo_pa = bs.codigo_pa
    --INNER JOIN EQTLINFO_RAW.OPER_GO.unidade_territorial ut ON ut.reg_eletrica_id = pa.reg_eletrica_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.regiao_eletrica rg ON rg.reg_eletrica_id = pa.reg_eletrica_id
    
WHERE
    oc.oco_status = 'F'
    AND ot.hot_vi_status = 4
    AND oc.oco_data_conclusao >= ('01/10/2023')
       --AND date_trunc('month',oc.OCO_DATA_NR) = '2025-01-01'::date
       AND tc.tca_descricao NOT LIKE ('%PTP%')
       AND  pa.pap_nome    NOT ILIKE ('%APOIO%')
       AND OC.TB_NATUREZA_ID = 1
AND oc.tb_tp_abrangencia = 'CR'
AND TIPO = 'P'
AND PREFIXO NOT ILIKE('MANOBRA%')


),

BASE_COMERCIAL AS (

    WITH DadosOS AS (
    SELECT 
        'GOIAS' AS Empresa,
        'A' AS atros_status,
        os.dt_programacao_os AS data_origem,
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
        os.sstipo_id AS TIPOSS,
        'COMERCIAL' AS abrangencia,
        TO_VARCHAR(os.cd_movto_os_comercial) AS OS_OPER,
        REGEXP_REPLACE(TO_VARCHAR(os.nr_os),'\\.0+$', '') AS OS,
        os.ostipo_id AS OSTIPO,
        os.ossubtipo_id AS ossubtipo,        
        rg.rel_descricao AS regional,
        pa.pap_nome AS SECCIONAL,
        mp.mnc_nome AS municipio,
        lo.loc_nome AS localidade,
        bs.bas_nome base,
        TRUNC(os.nr_uc, 0) AS uc,
        {{ normalize_prefix_model('PT.PRX_DESCRICAO',"'GO'") }} AS prefixo,
        NULL AS registro_exec,
        CASE
            WHEN (os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NOT NULL) THEN cc.cd_tp_conclusao_os
            ELSE cc.cd_tp_conclusao_os
        END AS cod_conclusao,        
        cm.descricao AS tipo_conclusao,
        NULL AS Cod_Subcausa,
   NULL AS subcausa,
        CASE           
            WHEN cm.tipo_conclusao = 'N' THEN 'P'
            WHEN cm.descricao= 'FATURA JÁ PAGA' THEN 'P'
            ELSE 'I'
        END TIPO,
        NULL AS TB_NATUREZA_ID,
        
        ROW_NUMBER() OVER (PARTITION BY os.cd_movto_os_comercial ORDER BY ac.atribuicao_os_id desc, cm.tipo_conclusao desc) AS rn
    FROM
        EQTLINFO_RAW.OPER_GO.movto_os_comercial os
        LEFT JOIN EQTLINFO_RAW.OPER_GO.bairro br ON br.bairro_id = os.cd_bairro
        LEFT JOIN EQTLINFO_RAW.OPER_GO.localidade lo ON lo.lc_id = br.lc_id
        LEFT JOIN EQTLINFO_RAW.OPER_GO.municipio mp ON mp.mnc_id = lo.MNC_ID
        LEFT JOIN EQTLINFO_RAW.OPER_GO.conclui_os_comercial cc ON cc.cd_movto_os_comercial = os.cd_movto_os_comercial
        LEFT JOIN EQTLINFO_RAW.OPER_GO.tipo_ocorrencia_corte oc ON oc.tpoco_corte_id = cc.cd_tp_ocorrencia_corte
        LEFT JOIN EQTLINFO_RAW.OPER_GO.atribui_os_comercial ac ON ac.cd_movto_os_comercial = os.cd_movto_os_comercial
        LEFT JOIN EQTLINFO_RAW.OPER_GO.prefixo_turma pt ON pt.prefixo_turma_id = ac.prefixo_turma_id
        LEFT JOIN EQTLINFO_RAW.OPER_GO.turma_os_comercial tc ON tc.atribuicao_os_id = ac.atribuicao_os_id
        LEFT JOIN EQTLINFO_RAW.OPER_GO.base bs ON bs.base_id = br.base_id
        LEFT JOIN EQTLINFO_RAW.OPER_GO.ponto_apoio pa ON pa.codigo_pa = bs.codigo_pa
        LEFT JOIN EQTLINFO_RAW.OPER_GO.regiao_eletrica rg ON rg.reg_eletrica_id = pa.reg_eletrica_id 
        LEFT JOIN EQTLINFO_RAW.OPER_GO.code_medida cm ON cm.ossubtipo_id = os.ossubtipo_id AND cc.cd_tp_conclusao_os = cm.code_medida_id
    WHERE    
        cc.dt_conclusao >= TO_DATE('01/10/2023','DD/MM/YYYY')
        AND cc.cd_tp_conclusao_os NOT IN ('8','126','156')
        AND os.ostipo_id NOT IN ('CT','DS')
        AND TIPO = 'P'
        AND cm.descricao NOT IN ('REJEIÇÃO PARA CANCELAMENTO')
    AND cm.descricao NOT IN ('REJEIÇÃO PARA CANCELAMENTO','02 - NECESSARIO OBRA MT/BT PARA ATENDIMENTO DA SS','03 - OBRA MT/BT NAO CONCLUIDA','NECESSÁRIO EXTENSÃO DE REDE')        
        

)
SELECT
    'GOIAS' AS Empresa,
    atros_status,
    DATA_ORIGEM,
    data_abertura,
    data_carga,
    oco_data_acionamento,
    inicio_deslocamento,
    oco_data_chegada,
    OCO_DATA_CONCLUSAO,
    tmp,
    tmd,
    TMA,
    tmat,
    bairro,
    TIPOSS,
    ABRANGENCIA,
    OS_OPER,
    OS,
    OSTIPO,
    ossubtipo,
    regional,
    SECCIONAL,
    municipio,
    localidade,
    BASE,
    uc,
    prefixo,
    registro_exec,
    cod_conclusao,
    tipo_conclusao,
    Cod_Subcausa,
   subcausa,
    TIPO,
    TB_NATUREZA_ID
FROM
    DadosOS
WHERE
    rn = 1
),
BASE_PERDAS AS(
SELECT 
'EQTL GO' AS EMPRESA,
'A' AS ATROS_STATUS,
GPA.DT_SOLICITACAO AS  DATA_ORIGEM,
GPA.DT_SOLICITACAO AS DATA_ABERTURA,
GPA.DATA_DADOS AS DATA_CARGA,
NULL AS OCO_DATA_ACIONAMENTO,
NULL AS INICIO_DESLOCAMENTO,
NULL AS OCO_DATA_CHEGADA,
GPA.DT_CONCLUSAO AS OCO_DATA_CONCLUSAO,
NULL AS TMP,
NULL AS TMD,
NULL AS TMA,
NULL AS TMAT,
NULL AS BAIRRO,
GPA.CODIGO_IRREGULARIDADE_CAMPO AS TIPO_SS,
'COMERCIAL'ABRANGENCIA,
TO_VARCHAR(GPA.NR_OS) OS_OPER,
TO_VARCHAR(GPA.NR_OS) AS OS,
'FS' AS OSTIPO,
GPA.CODIGO_IRREGULARIDADE_CAMPO AS OSSUBTIPO,
NULL AS REGIONAL,
NULL AS SECCIONAL,
NULL AS municipio,
NULL AS LOCALIDADE,
NULL AS BASE,
TRUNC(GPA.NR_UC,0) AS UC,
GPA.PRX_DESCRICAO AS PREFIXO,
GPA.DS_REGISTRO_ATENDIMENTO AS REGISTRO_EXEC,
GPA.CODIGO_IRREGULARIDADE_CAMPO COD_CONCLUSAO,
GPA.DES_IRREG_ENCONTRADA AS TIPO_CONCLUSAO,
NULL COD_SUBCAUSA,
NULL AS SUBCAUSA,
'P'TIPO,
NULL AS TB_NATUREZA_ID

 FROM EQTLINFO_PRD.EQTL_GO.ODS_GSPERDAS GPA
WHERE GPA.RESULTADO_INSPECAO = 1
AND GPA.DT_SOLICITACAO >= '2023-10-01'

),

BASE_MT AS(
select 
 'GOIAS' AS Empresa,
 'A' AS atros_status,
 os.dt_inicio as data_origem,
 os.dt_inicio AS data_abertura,
 CURRENT_TIMESTAMP AS data_carga,
  null as oco_data_acionamento,
  os.dt_deslocamento as inicio_deslocamento,
  null as oco_data_chegada,    
  OS.dt_fim as oco_data_conclusao,
  null as tmp,
  null as tmd,
  null as tma,
  null AS tmat,
  br.bai_nome AS bairro,
  'MT' AS tipo_ss,
  'COMERCIAL' AS abrangencia,
  REGEXP_REPLACE(OS.CD_MOVTO_OS_MISCELANEA,'\\.0+$', '') AS os_oper,
  RTRIM(OS.MSC_ANO,'.00') || '-' || RTRIM(OS.MSC_MES,'.00') || '-' || RTRIM(OS.MSC_NUMERO,'.00') AS os,
  'MT' AS ostipo,
  CM.TB_MT_MISCELANEA_DESCRICAO AS ossubtipo,
   rg.rel_descricao AS regional,
    pa.pap_nome AS SECCIONAL,
    mp.mnc_nome AS municipio,
    lo.loc_nome AS localidade,
    bs.bas_nome AS base,
    TRUNC(OS.cr_numero, 0) AS uc,
    {{ normalize_prefix_model('PT.PRX_DESCRICAO',"'GO'") }} AS prefixo,
    OS.OBSERVACAO AS registro_exec,
    RTRIM(TO_CHAR(OS.TB_MT_MISCELANEA_ID),'.00') AS cod_conclusao,
     CM.TB_MT_MISCELANEA_DESCRICAO AS tipo_conclusao,
     NULL AS Cod_Subcausa,
   NULL AS subcausa,
   'P' AS tipo,
   NULL AS TB_NATUREZA_ID
FROM
         EQTLINFO_RAW.OPER_GO.MOVTO_OS_MISCELANEA os
        LEFT JOIN EQTLINFO_RAW.OPER_GO.bairro br ON br.bairro_id = os.bairro_id
        LEFT JOIN EQTLINFO_RAW.OPER_GO.localidade lo ON lo.lc_id = br.lc_id
        LEFT JOIN EQTLINFO_RAW.OPER_GO.municipio mp ON mp.mnc_id = lo.MNC_ID
        LEFT JOIN EQTLINFO_RAW.OPER_GO.CONCLUI_OS_MISCELANEA  cc ON cc.HIST_MSC_TURMA_ID  = os.CD_MOVTO_OS_MISCELANEA       
        LEFT JOIN EQTLINFO_RAW.OPER_GO.ATRIBUI_OS_MISCELANEA ac ON ac.CD_MOVTO_OS_MISCELANEA  = os.CD_MOVTO_OS_MISCELANEA
        LEFT JOIN EQTLINFO_RAW.OPER_GO.PREFIXO_TURMA pt ON pt.prefixo_turma_id = ac.prefixo_turma_id
        LEFT JOIN EQTLINFO_RAW.OPER_GO.TURMA_OS_MISCELANEA tc ON tc.ATRIBUICAO_MSC_ID  = ac.ATRIBUICAO_MSC_ID 
        LEFT JOIN EQTLINFO_RAW.OPER_GO.base bs ON bs.base_id = OS.base_id
        LEFT JOIN EQTLINFO_RAW.OPER_GO.ponto_apoio pa ON pa.codigo_pa = bs.codigo_pa
        LEFT JOIN EQTLINFO_RAW.OPER_GO.regiao_eletrica rg ON rg.reg_eletrica_id = pa.reg_eletrica_id 
        LEFT JOIN EQTLINFO_RAW.OPER_GO.motivo_da_miscelanea cm ON cm.TB_MT_MISCELANEA_ID  = os.TB_MT_MISCELANEA_ID
        
        WHERE    
        cc.dt_conclusao >= '2023-10-01'
        AND OS.STATUS_OS = 'F'
        AND TRUNC(OS.cr_numero, 0)IS NOT NULL
),
BASE_GERAL AS (
    SELECT * FROM BASE_EMERGENCIAL
    UNION ALL
    SELECT * FROM BASE_COMERCIAL
    UNION ALL 
    SELECT * FROM BASE_PERDAS
    UNION ALL
    SELECT * FROM BASE_MT
),
RECLAMACOES AS (
    SELECT *
    FROM BASE_EMERGENCIAL
    WHERE tb_natureza_id = 1
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
    s.OSSUBTIPO             AS OSSUBTIPO_ORIGEM,
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
    ,'[^A-Z0-9]', '') PREFIXO_UNICO,

FROM RECLAMACOES r

LEFT JOIN BASE_GERAL s
    ON r.UC = s.UC
    AND r.DATA_ORIGEM > s.OCO_DATA_CONCLUSAO
    AND DATEDIFF('day', s.OCO_DATA_CONCLUSAO, r.DATA_ORIGEM) BETWEEN 0 AND 90

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY r.OS_OPER
    ORDER BY s.OCO_DATA_CONCLUSAO DESC NULLS LAST
) = 1