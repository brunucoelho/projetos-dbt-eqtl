{{config(
    materialized='table'
)}}

WITH BASE_EMERGENCIAL AS (

        SELECT
    'MARANHAO' AS Empresa,
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

    DATEDIFF('hour', oc.oco_data_nr, oc.oco_data_aceite) +
    DATEDIFF('hour', oc.oco_data_aceite, oc.oco_data_chegada) +
    DATEDIFF('hour', oc.oco_data_chegada, oc.oco_data_conclusao) AS tmat,

    br.bai_nome AS bairro,
    'NR' AS tipo_ss,

    DECODE(
        oc.tb_tp_abrangencia,
        'CR','CONSUMIDOR',
        'TF','TRANSFORMADOR',
        'CH','CHAVE',
        'AL','ALIMENTADOR',
        'SE','SUBESTACAO',
        oc.tb_tp_abrangencia
    ) AS abrangencia,

    RTRIM(oc.oco_numero,'.00') || '-' ||
    RTRIM(oc.oco_mes,'.00') || '-' ||
    RTRIM(oc.oco_ano,'.00') AS os_oper,

    RTRIM(oc.oco_numero,'.00') || '-' ||
    RTRIM(oc.oco_mes,'.00') || '-' ||
    RTRIM(oc.oco_ano,'.00') AS os,

    'NR' AS ostipo,

    CASE
        WHEN oc.tb_tp_abrangencia IN ('CR','NI') THEN 'IND'
        ELSE 'COL'
    END AS ossubtipo,

    rg.rel_descricao AS regional,
    pa.pap_nome AS SECCIONAL,
    mp.mnc_nome AS municipio,
    lo.loc_nome AS localidade,
    bs.bas_nome AS base,
    oc.cr_numero::bigint::text AS uc,
    {{ normalize_prefix_model('pt.prx_descricao',"'MA'") }} AS prefixo,
    oc.oco_observacoes_atendimento AS registro_exec,

    RTRIM(TO_CHAR(oc.tb_causa_id),'.00') AS cod_conclusao,
    tc.tca_descricao AS tipo_conclusao,
    TO_CHAR(sub.tb_subcausa_id) AS Cod_Subcausa,
    sub.tsc_descricao AS subcausa,

    CASE
        WHEN oc.tb_tp_abrangencia IS NULL OR oc.tb_causa_id IS NULL THEN '?'
        WHEN oc.tb_causa_id IN (252,262,273,274,276,287) THEN 'I'
        ELSE 'P'
    END AS tipo,

    TO_CHAR(oc.tb_natureza_id) AS TB_NATUREZA_ID

FROM EQTLINFO_RAW.OPER_MA.ocorrencia oc

LEFT JOIN EQTLINFO_RAW.OPER_MA.tipo_de_subcausa sub
       ON sub.tb_subcausa_id = oc.tb_subcausa_id

INNER JOIN EQTLINFO_RAW.OPER_MA.tipo_de_causa tc
        ON tc.tb_causa_id = oc.tb_causa_id

INNER JOIN EQTLINFO_RAW.OPER_MA.historico_ocorrencia_turma ot
        ON ot.ocorrencia_id = oc.ocorrencia_id

INNER JOIN EQTLINFO_RAW.OPER_MA.historico_turma_plantao tp
        ON tp.hist_turma_plantao_id = ot.hist_turma_plantao_id

INNER JOIN EQTLINFO_RAW.OPER_MA.prefixo_turma pt
        ON pt.prefixo_turma_id = tp.prefixo_turma_id
INNER JOIN EQTLINFO_RAW.OPER_MA.bairro br        ON br.bairro_id = oc.bairro_id

INNER JOIN EQTLINFO_RAW.OPER_MA.localidade lo        ON lo.lc_id = br.lc_id

INNER JOIN EQTLINFO_RAW.OPER_MA.municipio mp        ON mp.mnc_id = lo.mnc_id

INNER JOIN EQTLINFO_RAW.OPER_MA.base bs        ON bs.base_id = mp.base_id

INNER JOIN EQTLINFO_RAW.OPER_MA.ponto_apoio pa        ON pa.codigo_pa = bs.codigo_pa

INNER JOIN EQTLINFO_RAW.OPER_MA.regiao_eletrica rg        ON rg.reg_eletrica_id = pa.reg_eletrica_id

WHERE
    oc.oco_status = 'F'
    AND ot.hot_vi_status = 4
    AND oc.oco_data_conclusao >= TO_DATE('01/10/2023','DD/MM/YYYY')
    AND oc.tb_natureza_id = 5
    --AND pa.codigo_pa < 100
    AND oc.tb_tp_abrangencia = 'CR'
    -- filtro do tipo = 'P' (repetindo a lógica do CASE)
    AND oc.tb_causa_id NOT IN (252,262,273,274,276,287)
    AND oc.tb_tp_abrangencia IS NOT NULL
    AND oc.tb_causa_id IS NOT NULL
    -- correção lógica do prefixo
    AND pt.prx_descricao NOT ILIKE '%OFS001%'
    AND pt.prx_descricao NOT ILIKE '%SOL%'
    AND pt.prx_descricao NOT ILIKE '%MAN%'

),

BASE_EMERGENCIAL_ADMS AS (
WITH reclam AS (
    SELECT  
        tck.INCIDENT_GID AS INC_ID_INTERNO,
        TCK.SERVICE_DELIVERY_POINT_CUSTOMID AS TCK_UC,
        ROW_NUMBER() OVER (
            PARTITION BY tck.INCIDENT_GID  
            ORDER BY TCK.SERVICE_DELIVERY_POINT_CUSTOMID
        ) AS rank4              
    FROM EQTLINFO_RAW.ADMS.OMS_PHONE_CALL_EVENT TCK
    INNER JOIN EQTLINFO_RAW.ADMS.OMS_EVENT_REASON EVR 
        ON EVR.GID = TCK.EVENT_REASON_GID
    QUALIFY rank4 = 1
),

crew AS (
    SELECT
        INCIDENT_GID,
       CREW_CUSTOMID AS NAME,
        ROW_NUMBER() OVER (
            PARTITION BY INCIDENT_GID
            ORDER BY NAME
        ) AS rk
   FROM EQTLINFO_RAW.ADMS.OMS_INC_CREW
    QUALIFY rk = 1
)

SELECT 
'MARANHAO' AS Empresa,
'A' AS atros_status,
DATEADD(hour, -3, oii.OUTAGE_TIME) AS data_origem, 
CAST(NULL AS DATE) AS  DATA_ABERTURA,
CURRENT_TIMESTAMP AS data_carga,
CAST(NULL AS DATE) AS OCO_DATA_ACIONAMENTO, 
CAST(NULL AS DATE) AS inicio_deslocamento,
CAST(NULL AS DATE) AS OCO_DATA_CHEGADA, 
MAX(CASE WHEN ois.NAME = 'ENCERRADO EM CAMPO' THEN DATEADD(hour, -3,oiis.INCIDENT_STATUS_TIMESTAMP)
ELSE NULL
END) AS OCO_DATA_CONCLUSAO,
NULL AS tmp,
 null AS tmd,
 null AS tma,
 NULL AS tmat, 
NULL AS bairro,
'NR' AS tipo_ss,
DECODE(e.DATA3, 
    'CR', 'CONSUMIDOR',
    'TF', 'TRANSFORMADOR',
    'CH', 'CHAVE',
    'AL', 'ALIMENTADOR',
    'SE','GRUPO_MEDICAO',
    'GM', 'GRUPO_MEDICAO',
    e.DATA3) AS abrangencia,
oii.uid AS os_oper, 
oii.uid AS os,
'NR' AS ostipo,
CASE
    WHEN e.DATA3 IN ('CR','NI') THEN 'IND'
    ELSE 'COL'
END AS ossubtipo,
SG.REGIONAL AS regional,
SG.SECTIONAL AS SECCIONAL,
SG.CITY AS municipio,
SG.NEIGHBORHOOD AS localidade,
SG.BASE AS base,
CASE WHEN REGEXP_REPLACE(uc.TCK_UC, '[^0-9]', '') <> '' THEN REGEXP_REPLACE(uc.TCK_UC, '[^0-9]', '') END  uc,
{{ normalize_prefix_model('prx.NAME',"'MA'") }}  AS prefixo,
NULL AS registro_exec,    
tc.code AS cod_conclusao,
tc.NAME AS tipo_conclusao,
sub.CODE AS Cod_Subcausa,
sub.NAME AS subcausa,
CASE
    WHEN e.DATA3 IS NULL OR oii.INCIDENT_CAUSE_GID IS NULL THEN '?'
    WHEN tc.code IN ('252','262','273','274','276','287') THEN 'I'  
    ELSE 'P'
END AS tipo,
OCT.NAME AS TB_NATUREZA_ID   

FROM eqtlinfo_raw.adms.oms_inc_device_ext e 
INNER JOIN {{ ref("stg_adms__oms_inc_incident") }} oii     ON e.incident_gid = oii.gid
LEFT JOIN EQTLINFO_RAW.ADMS.OMS_INC_INCIDENT_STATUS oiis ON oii.GID = oiis.INCIDENT_GID
LEFT JOIN EQTLINFO_RAW.ADMS.OMS_INC_STATUS ois ON oiis.INCIDENT_STATUS_GID = ois.GID
INNER JOIN reclam uc     ON oii.gid = uc.INC_ID_INTERNO 
INNER JOIN EQTLINFO_RAW.ADMS.PRM_INCIDENT_COMPANY PRM     ON PRM.IncidentRef = OII.GID
INNER JOIN eqtlinfo_raw.adms.SNM_GEOAREA SG     ON E.DATA1 = SG.ID
INNER JOIN crew prx     ON prx.INCIDENT_GID = OII.GID
JOIN EQTLINFO_RAW.ADMS.OMS_INC_CAUSE tc     ON tc.GID = oii.INCIDENT_CAUSE_GID
JOIN EQTLINFO_RAW.ADMS.OMS_INC_SUBCAUSE sub     ON sub.GID = oii.INCIDENT_SUBCAUSE_GID
JOIN EQTLINFO_RAW.ADMS.OMS_CONSTRUCTION_TYPE OCT     ON OCT.GID = oii.CONSTRUCTION_TYPE_GID

WHERE PRM.Company = 'MA'

AND DATEADD(hour, -3, oii.OUTAGE_TIME) >= '2025-09-01'
AND e.DATA3 IN ('GM','CR')
AND OCT.NAME = 'INTEMPESTIVO'
AND prx.NAME NOT ILIKE '%SOL%'
AND prx.NAME NOT ILIKE '%MAN%'
AND (
    CASE
        WHEN e.DATA3 IS NULL OR oii.INCIDENT_CAUSE_GID IS NULL THEN '?'
        WHEN tc.code IN ('252','262','273','274','276','287') THEN 'I'
        ELSE 'P'
    END
) = 'P'
GROUP BY all
),

BASE_COMERCIAL AS (

     SELECT
    'MARANHAO' AS EMPRESA,
    act.TX_STATUS ATROS_STATUS,
    act.DT_ACTIVITY DATA_ORIGEM,    
    -- TO_TIMESTAMP(act.TX_EQ_DATAABERTURA, 'DD/MM/YYYY HH24:MI:SS') AS 
    CAST(NULL AS DATE) DATA_ABERTURA,

    CURRENT_TIMESTAMP() AS DATA_CARGA,
    act.DT_ACTIVITY OCO_DATA_ACIONAMENTO,
    case 
when regexp_like( act.DATA_HORA_ACAO_DESLOCAMENTO, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_DESLOCAMENTO, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.DATA_HORA_ACAO_DESLOCAMENTO, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_DESLOCAMENTO, 'YYYY-MM-DD')::date
end INICIO_DESLOCAMENTO,  
    case 
when regexp_like( act.DATA_HORA_ACAO_INICIO, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_INICIO, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.DATA_HORA_ACAO_INICIO, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_INICIO, 'YYYY-MM-DD')::date
end OCO_DATA_CHEGADA,        
    case 
when regexp_like( act.data_hora_acao_conclusao, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.data_hora_acao_conclusao, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.data_hora_acao_conclusao, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.data_hora_acao_conclusao, 'YYYY-MM-DD')::date
end oco_data_conclusao,
NULL AS TMP,
NULL AS TMD,
NULL AS TMA,
NULL AS TMAT,
TIPO_LOCALIZACAO_UC AS BAIRRO,
  TX_EQ_CODE TIPO_SS,
  'COMERCIAL' ABRANGENCIA,
    TO_CHAR(act.tx_os) AS OS_OPER,
    TO_CHAR(act.tx_os) AS os,
    act.tx_eq_tiponota AS OSTIPO,
    act.tx_eq_grupocode AS OSSUBTIPO,
    re.REL_DESCRICAO AS REGIONAL,
    pa.pap_nome AS SECCIONAL,
    act.tx_city AS MUNICIPIO,
    act.tx_city AS LOCALIDADE,
 B.BAS_NOME AS BASE,
  ACT.TX_EQ_INSTALACAO AS UC,
    {{ normalize_prefix_model('act.tx_resourceexternalid',"'MA'") }} AS PREFIXO,
    ACT.TX_EQ_OBSERVACAO REGISTRO_EXEC,        
    cm.code_medida_id AS COD_CONCLUSAO,
    cm.descricao TIPO_CONCLUSAO,
    NULL AS COD_SUBCAUSA,
    cm.grupo_code_medida_id AS SUBCAUSA,
    CASE 
    WHEN LOWER(act.tx_status)= 'completed' THEN 'P'
    ELSE 'I'
  END TIPO,
    NULL AS TB_NATUREZA_ID
FROM eqtlinfo_raw.siga.tb_ofsc_resources_rt  res
JOIN eqtlinfo_raw.siga.tb_ofsc_activities_rt act ON act.nb_resourceid = res.nb_id
LEFT JOIN eqtlinfo_raw.oper_ma.code_medida cm ON
    cm.code_medida_id = SUBSTR(NVL(act.tx_eq_tipoconclusaoexec, act.tx_eq_tipoconclusaonaoexec), -4)
    AND cm.grupo_code_medida_id = act.tx_eq_grupocodemedida
    AND cm.ossubtipo_id = act.tx_eq_grupocode
INNER JOIN eqtlinfo_raw.oper_ma.municipio m ON m.mnc_id = act.nb_eq_codigomunicipio
INNER JOIN eqtlinfo_raw.oper_ma.base b ON b.base_id = m.base_id
INNER JOIN eqtlinfo_raw.oper_ma.ponto_apoio pa ON pa.codigo_pa = b.codigo_pa
INNER JOIN eqtlinfo_raw.oper_ma.regiao_eletrica re ON re.reg_eletrica_id = pa.reg_eletrica_id
WHERE act.dt_activity >= '2023-10-01' AND act.dt_activity < '2025-09-01'
AND TX_STATE IN ('MA')
AND ACT.TX_EQ_INSTALACAO <> 0
    AND act.tx_status IN ('completed','complete')
   -- AND act.tx_resourceexternalid NOT IN ('PA_PA-BEL-S108M','PA_PA-BEL-S109M','PA_PA-BEL-S110M','PA_PA-BEL-S111M','PA_PA-BEL-S113M','PA_PA-BEL-S114M','PA_PA-BEL-S115M','PA_PA-BEL-S116M','PA_PA-BEL-S117M')
    AND act.tx_eq_tiponota NOT IN ('CT','DS','NT','NR','FS','PA','MT')
   -- AND act.tx_eq_tiponota IN ('LN','RI','LG','RL','IS','DR','CT','DS','M1','MQ','MM','TR')
    AND cm.descricao NOT IN ('SOBRAS','BAIXA POR RAJADA/ARRECADAÇÃO','REJEICAO PARA CANCELAMENTO','REJEIÇÃO PARA CANCELAMENTO')
    AND cm.descricao  NOT IN ('NAO EXECUTADO')

),

BASE_COMERCIAL_ADMS AS (

     SELECT
    'MARANHAO' AS EMPRESA,
    act.TX_STATUS ATROS_STATUS,
    act.DT_ACTIVITY DATA_ORIGEM,    
    -- TO_TIMESTAMP(act.TX_EQ_DATAABERTURA, 'DD/MM/YYYY HH24:MI:SS') AS 
    CAST(NULL AS DATE) DATA_ABERTURA,

    CURRENT_TIMESTAMP() AS DATA_CARGA,
    act.DT_ACTIVITY OCO_DATA_ACIONAMENTO,
    case 
when regexp_like( act.DATA_HORA_ACAO_DESLOCAMENTO, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_DESLOCAMENTO, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.DATA_HORA_ACAO_DESLOCAMENTO, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_DESLOCAMENTO, 'YYYY-MM-DD')::date
end INICIO_DESLOCAMENTO,  
    case 
when regexp_like( act.DATA_HORA_ACAO_INICIO, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_INICIO, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.DATA_HORA_ACAO_INICIO, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_INICIO, 'YYYY-MM-DD')::date
end OCO_DATA_CHEGADA,        
    case 
when regexp_like( act.data_hora_acao_conclusao, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.data_hora_acao_conclusao, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.data_hora_acao_conclusao, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.data_hora_acao_conclusao, 'YYYY-MM-DD')::date
end oco_data_conclusao,
NULL AS TMP,
NULL AS TMD,
NULL AS TMA,
NULL AS TMAT,
TIPO_LOCALIZACAO_UC AS BAIRRO,
  TX_EQ_CODE TIPO_SS,
  'COMERCIAL' ABRANGENCIA,
    TO_CHAR(act.tx_os) AS OS_OPER,
    TO_CHAR(act.tx_os) AS os,
    act.tx_eq_tiponota AS OSTIPO,
    act.tx_eq_grupocode AS OSSUBTIPO,
    re.REL_DESCRICAO AS REGIONAL,
    pa.pap_nome AS SECCIONAL,
    act.tx_city AS MUNICIPIO,
    act.tx_city AS LOCALIDADE,
 B.BAS_NOME AS BASE,
ACT.TX_EQ_INSTALACAO::bigint::text AS UC,  
    {{ normalize_prefix_model('act.tx_resourceexternalid',"'MA'") }} AS PREFIXO,
    ACT.TX_EQ_OBSERVACAO REGISTRO_EXEC,        
    cm.code_medida_id AS COD_CONCLUSAO,
    cm.descricao TIPO_CONCLUSAO,
    NULL AS COD_SUBCAUSA,
    cm.grupo_code_medida_id AS SUBCAUSA,
    CASE 
    WHEN LOWER(act.tx_status)= 'completed' THEN 'P'
    ELSE 'I'
  END TIPO,
    NULL AS TB_NATUREZA_ID
FROM eqtlinfo_raw.siga.tb_ofsc_resources_rt  res
JOIN eqtlinfo_raw.siga.tb_ofsc_activities_rt act ON act.nb_resourceid = res.nb_id
LEFT JOIN eqtlinfo_raw.oper_ma.code_medida cm ON
    cm.code_medida_id = SUBSTR(NVL(act.tx_eq_tipoconclusaoexec, act.tx_eq_tipoconclusaonaoexec), -4)
    AND cm.grupo_code_medida_id = act.tx_eq_grupocodemedida
    AND cm.ossubtipo_id = act.tx_eq_grupocode
INNER JOIN eqtlinfo_raw.oper_ma.municipio m ON '21' || LPAD(CAST(m.MNC_ID AS INTEGER)::VARCHAR, 5, '0')=ACT.NB_EQ_CODIGOMUNICIPIO
INNER JOIN eqtlinfo_raw.oper_ma.base b ON b.base_id = m.base_id
INNER JOIN eqtlinfo_raw.oper_ma.ponto_apoio pa ON pa.codigo_pa = b.codigo_pa
INNER JOIN eqtlinfo_raw.oper_ma.regiao_eletrica re ON re.reg_eletrica_id = pa.reg_eletrica_id
WHERE DATE_TRUNC('month', act.dt_activity) >= '2025-09-01'
AND TX_STATE IN ('MA')
AND ACT.TX_EQ_INSTALACAO <> 0
    AND act.tx_status IN ('completed','complete')   
    AND act.tx_eq_tiponota NOT IN ('CT','DS','NT','NR','FS','PA')
   -- AND act.tx_eq_tiponota IN ('LN','RI','LG','RL','IS','DR','CT','DS','M1','MQ','MM','TR')
    AND cm.descricao NOT IN ('SOBRAS','BAIXA POR RAJADA/ARRECADAÇÃO','REJEICAO PARA CANCELAMENTO','REJEIÇÃO PARA CANCELAMENTO')
    AND cm.descricao  NOT IN ('NAO EXECUTADO')
    
 ),   
    
   BASE_COMERCIAL_MT AS ( 
   SELECT
    'MARANHAO' AS EMPRESA,
    act.TX_STATUS ATROS_STATUS,
    act.DT_ACTIVITY DATA_ORIGEM,    
    -- TO_TIMESTAMP(act.TX_EQ_DATAABERTURA, 'DD/MM/YYYY HH24:MI:SS') AS 
    CAST(NULL AS DATE) DATA_ABERTURA,

    CURRENT_TIMESTAMP() AS DATA_CARGA,
    act.DT_ACTIVITY OCO_DATA_ACIONAMENTO,
    case 
when regexp_like( act.DATA_HORA_ACAO_DESLOCAMENTO, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_DESLOCAMENTO, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.DATA_HORA_ACAO_DESLOCAMENTO, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_DESLOCAMENTO, 'YYYY-MM-DD')::date
end INICIO_DESLOCAMENTO,  
    case 
when regexp_like( act.DATA_HORA_ACAO_INICIO, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_INICIO, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.DATA_HORA_ACAO_INICIO, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.DATA_HORA_ACAO_INICIO, 'YYYY-MM-DD')::date
end OCO_DATA_CHEGADA,        
    case 
when regexp_like( act.data_hora_acao_conclusao, '^\\d{4}-\\d{2}-\\d{2} \\d{2}[:]\\d{2}') then TO_TIMESTAMP(act.data_hora_acao_conclusao, 'YYYY-MM-DD HH24:MI')::date
when regexp_like( act.data_hora_acao_conclusao, '^\\d{4}-\\d{2}-\\d{2}') then TO_TIMESTAMP(act.data_hora_acao_conclusao, 'YYYY-MM-DD')::date
end oco_data_conclusao,
NULL AS TMP,
NULL AS TMD,
NULL AS TMA,
NULL AS TMAT,
TIPO_LOCALIZACAO_UC AS BAIRRO,
  TX_EQ_CODE TIPO_SS,
  'COMERCIAL' ABRANGENCIA,
    TO_CHAR(act.tx_os) AS OS_OPER,
    TO_CHAR(act.nb_id) AS os,
    act.tx_eq_tiponota AS OSTIPO,
    act.tx_eq_grupocode AS OSSUBTIPO,
    null AS REGIONAL,
    null AS SECCIONAL,
    null AS MUNICIPIO,
    null AS LOCALIDADE,
    null AS BASE,
  ACT.TX_EQ_INSTALACAO ::bigint::text AS UC,
    {{ normalize_prefix_model('act.tx_resourceexternalid',"'MA'") }}  AS PREFIXO,
    ACT.TX_EQ_OBSERVACAO REGISTRO_EXEC,        
    cm.code_medida_id AS COD_CONCLUSAO,
    cm.descricao TIPO_CONCLUSAO,
    NULL AS COD_SUBCAUSA,
    cm.grupo_code_medida_id AS SUBCAUSA,
    CASE 
    WHEN LOWER(act.tx_status)= 'completed' THEN 'P'
    ELSE 'I'
  END TIPO,
    NULL AS TB_NATUREZA_ID
FROM eqtlinfo_raw.siga.tb_ofsc_resources_rt  res
JOIN eqtlinfo_raw.siga.tb_ofsc_activities_rt act ON act.nb_resourceid = res.nb_id
LEFT JOIN eqtlinfo_raw.oper_ma.code_medida cm ON
    cm.code_medida_id = SUBSTR(NVL(act.tx_eq_tipoconclusaoexec, act.tx_eq_tipoconclusaonaoexec), -4)
    AND cm.grupo_code_medida_id = act.tx_eq_grupocodemedida
    AND cm.ossubtipo_id = act.tx_eq_grupocode
--INNER JOIN eqtlinfo_raw.oper_ma.municipio m ON m.mnc_id = act.nb_eq_codigomunicipio
--INNER JOIN eqtlinfo_raw.oper_ma.base b ON b.base_id = m.base_id
--INNER JOIN eqtlinfo_raw.oper_ma.ponto_apoio pa ON pa.codigo_pa = b.codigo_pa
--INNER JOIN eqtlinfo_raw.oper_ma.regiao_eletrica re ON re.reg_eletrica_id = pa.reg_eletrica_id
WHERE act.dt_activity >= '2025-09-01'
AND TX_STATE IN ('MA')
AND ACT.TX_EQ_INSTALACAO <> 0
    AND act.tx_status IN ('completed','complete')
   -- AND act.tx_resourceexternalid NOT IN ('PA_PA-BEL-S108M','PA_PA-BEL-S109M','PA_PA-BEL-S110M','PA_PA-BEL-S111M','PA_PA-BEL-S113M','PA_PA-BEL-S114M','PA_PA-BEL-S115M','PA_PA-BEL-S116M','PA_PA-BEL-S117M')
    AND act.tx_eq_tiponota  IN ('MT')
   -- AND act.tx_eq_tiponota IN ('LN','RI','LG','RL','IS','DR','CT','DS','M1','MQ','MM','TR')
    AND cm.descricao NOT IN ('SOBRAS','BAIXA POR RAJADA/ARRECADAÇÃO','REJEICAO PARA CANCELAMENTO','REJEIÇÃO PARA CANCELAMENTO')
    AND cm.descricao  NOT IN ('NAO EXECUTADO')
    
),



BASE_PERDAS AS(
SELECT 
'MARANHAO' AS EMPRESA,
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
CASE 
 WHEN GPA.TIPO_NOTA IN ('13','150','33','336','50','55','561','58','814') THEN  'FS'
 ELSE GPA.TIPO_NOTA
END  AS OSTIPO,
GPA.CODIFICACAO AS OSSUBTIPO,
GPA.REGIONAL,
GPA.POLO AS SECCIONAL,
GPA.MUNICIPIO AS municipio,
GPA.LOCALIDADE AS LOCALIDADE,
NULL AS BASE,
GPA.INSTALACAO  AS UC,
{{ normalize_prefix_model('NR_VIATURA',"'MA'") }} AS PREFIXO,
NULL AS REGISTRO_EXEC,
to_char(IRREGULARIDADE) COD_CONCLUSAO,
CLASSIFICACAO_IRREG AS TIPO_CONCLUSAO,
NULL COD_SUBCAUSA,
NULL AS SUBCAUSA,
'P'TIPO,
NULL AS TB_NATUREZA_ID

   FROM EQTLINFO_PRD.GESTINFO_CORP.GIFC_plano_acoes GPA
WHERE UF = 'MA'
AND NORMALIZACAO = 1
AND DATA_NOTA >= '2023-10-01'

),
BASE_GERAL AS (
    SELECT * FROM BASE_EMERGENCIAL
    UNION ALL
    SELECT * FROM BASE_EMERGENCIAL_ADMS
    UNION ALL
    SELECT * FROM BASE_COMERCIAL
    UNION ALL
    SELECT * FROM BASE_COMERCIAL_ADMS
    UNION ALL
    SELECT * FROM BASE_COMERCIAL_MT
    UNION ALL 
    SELECT * FROM BASE_PERDAS
),
RECLAMACOES AS (
    SELECT *
    FROM BASE_EMERGENCIAL    
    WHERE tb_natureza_id = 5
   UNION ALL 
    SELECT * 
    FROM BASE_EMERGENCIAL_ADMS
    WHERE TB_NATUREZA_ID = 'INTEMPESTIVO'
    
)

SELECT

    /* =====================================================
       EVENTO ATUAL (RECLAMAÇÃO EMERGENCIAL)
       ===================================================== */
 r.DATA_CARGA,
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