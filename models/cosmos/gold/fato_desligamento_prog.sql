{{
  config(
    materialized='incremental',
    tags=['gold', 'final', 'desligamento']
  )
}}

{% set month_ref = get_month_ref() %}

WITH CTE_RS AS (
    SELECT 
        'EQTL_RS' AS DISTRIBUIDORA,
        K.ANO,
        K.MES,
        TO_CHAR(TO_DATE(K.ANO||K.MES,'YYYYMM'),'YYYYMM') COMPETENCIA,
        K.EQUIPE,
        NVL(SUM(CASE WHEN K.LIMITES_LN = 'VIOLADA' THEN K.QUANT_OCO END),0) AS NUMERADOR,
        SUM(K.QUANT_OCO) AS DENOMINADOR     
    FROM (
        SELECT 
            P.EMPRESA,
            EXTRACT(YEAR FROM p.INI_PREV) ANO,
            EXTRACT(MONTH FROM p.INI_PREV) MES,
            FISCAL,
            P.REGIONAL,
            gdfc.equipe,
            CASE
                WHEN (STATUS = 'C') THEN 'CANCELADA'
                WHEN (STATUS = 'E') THEN 'PREPARAÇÃO'
                WHEN ((INI_PREV <= DATA) AND (FIM_PREV >= DATA_CONCLUSAO)) THEN 'OK'
                ELSE 'VIOLADA'
            END AS LIMITES_LN,
            COUNT(NUM_SI) QUANT_OCO
        FROM SB_PERFORMANCE.EQTL_CORP.PROGRAMADAS_RS p
        LEFT JOIN SB_OPERACAO.OPERACAO_RS.GESTAO_DEC_FEC_RS gdfc 
            ON gdfc.OCORRENCIA_ID = p.ID
        WHERE STATUS = 'F'
          AND TO_VARCHAR(INI_PREV, 'YYYYMM') = {{ month_ref }}
        GROUP BY 
            EXTRACT(YEAR FROM p.INI_PREV),
            EXTRACT(MONTH FROM p.INI_PREV),
            FISCAL,
            P.EMPRESA,
            CASE
                WHEN (STATUS = 'C') THEN 'CANCELADA'
                WHEN (STATUS = 'E') THEN 'PREPARAÇÃO'
                WHEN ((INI_PREV <= DATA) AND (FIM_PREV >= DATA_CONCLUSAO)) THEN 'OK'
                ELSE 'VIOLADA'
            END,
            P.REGIONAL,
            gdfc.equipe
    ) K
    WHERE K.EQUIPE IS NOT NULL
    GROUP BY K.ANO, K.MES, K.EQUIPE
),

dados_go AS (
    SELECT DISTINCT
        'EQTL_GO' AS EMPRESA,
        NVL(TO_CHAR(D.FIM_OCORRENCIA, 'YYYYMM'), TO_CHAR(D.INICIO_OCORRENCIA, 'YYYYMM')) AS COMPETENCIA,
        NVL(EXTRACT(YEAR FROM D.FIM_OCORRENCIA), EXTRACT(YEAR FROM D.INICIO_OCORRENCIA)) AS ANO, 
        NVL(EXTRACT(MONTH FROM D.FIM_OCORRENCIA), EXTRACT(MONTH FROM D.INICIO_OCORRENCIA)) AS MES,
        D.OCORRENCIA_ID,
        D.NATUREZA_PROGRAMACAO,
        D.VERIFICA_HORARIO,
        D.STATUS_PTP,
        HOT.HIST_TURMA_PLANTAO_ID,
        AC.PREFIXO_TURMA_ID,
        P.PRX_DESCRICAO AS PREFIXO
    FROM SB_PERFORMANCE.EQTL_CORP.PROGRAMADAS_GO D
    LEFT JOIN EQTLINFO_RAW.OPER_GO.HISTORICO_OCORRENCIA_TURMA HOT 
        ON D.OCORRENCIA_ID = HOT.OCORRENCIA_ID
    LEFT JOIN EQTLINFO_RAW.OPER_GO.ATRIBUI_OC_EMERGENCIAL AC 
        ON AC.OCORRENCIA_ID = D.OCORRENCIA_ID
        AND AC.TURMA_PLANTAO_ID = HOT.HIST_TURMA_PLANTAO_ID
    LEFT JOIN EQTLINFO_RAW.OPER_GO.PREFIXO_TURMA P 
        ON P.PREFIXO_TURMA_ID = AC.PREFIXO_TURMA_ID
    WHERE D.STATUS_PTP = 'EXECUTADA' 
      AND D.NATUREZA_PROGRAMACAO = 'PROGRAMADA'
      AND NVL(TO_CHAR(D.FIM_OCORRENCIA, 'YYYYMM'), TO_CHAR(D.INICIO_OCORRENCIA, 'YYYYMM')) = {{ month_ref }}
),

equipe_contrato AS (
    SELECT 
        G.SIGLA_EMPRESA AS EMPRESA,
        TRIM(TO_CHAR(EC.ANO,'0000')) || TRIM(TO_CHAR(EC.MES,'00')) AS COMPETENCIA,
        EC.CONTRATO,
        EC.PREFIXO,
        C.FORNECEDOR_SAP AS FORNECEDOR
    FROM SB_PERFORMANCE.EQTL_CORP.SLV_EQUIPE_CONTRATO EC
    LEFT JOIN SB_PERFORMANCE.SILVER.GLOSSARIO_EMPRESAS G 
        ON EC.COD_EMPRESA = G.COD_EMPRESA
    LEFT JOIN SB_PERFORMANCE.EQTL_CORP.SLV_CONTRATOS C 
        ON C.CONTRATO_SAP = EC.CONTRATO 
        AND C.COD_EMPRESA = EC.COD_EMPRESA
)

SELECT 
    -- =============================================
    -- CAMPOS PADRÃO (comum a todas as fatos)
    -- =============================================
    A.PREFIXO AS equipe,
    TO_DATE(A.COMPETENCIA, 'YYYYMM') AS data,
    f.polo_id AS polo_id,
    d.polo AS polo,
    z.contrato_id AS contrato_id,
    NVL(B.CONTRATO, 'AUSENTE') AS contrato,
    A.EMPRESA AS empresa,
    e.regional AS regional,
    B.FORNECEDOR AS fornecedor,
    
    -- =============================================
    -- CAMPOS ESPECÍFICOS DA FATO
    -- =============================================
    A.COMPETENCIA,
    TO_NUMBER(SUBSTR(A.COMPETENCIA, 1, 4)) AS ANO,
    TO_NUMBER(SUBSTR(A.COMPETENCIA, 5, 2)) AS MES,
    A.OCORRENCIA_ID,
    A.VERIFICA_HORARIO,
    'QTD_SERV_PROG_FORA_PRAZO_/_QTD_SERV_PROG' AS FORMULA,
    '%' AS UNIDADE

FROM dados_go A
LEFT JOIN equipe_contrato B 
    ON A.EMPRESA = B.EMPRESA 
    AND A.COMPETENCIA = B.COMPETENCIA 
    AND A.PREFIXO = B.PREFIXO
LEFT JOIN {{ ref('dim_equipes') }} c 
    ON A.PREFIXO = c.prefixo 
    AND SPLIT_PART(A.EMPRESA, '_', 2) = c.empresa
LEFT JOIN {{ ref('dim_polos') }} d 
    ON c.polo_id = d.cod_polo
LEFT JOIN {{ ref('dim_polos_cosmos') }} f
    ON d.polo = f.pol_nome
LEFT JOIN {{ ref('dim_regionais') }} e 
    ON d.cod_regional = e.cod_regional
LEFT JOIN {{ ref('dim_contratos_cosmos') }} z
    ON B.CONTRATO = z.cod_sap
LEFT JOIN {{ ref('dim_polos_cosmos') }} ax
    ON UPPER(TRANSLATE(
        REPLACE(d.polo, '_', ' '),
        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ',
        'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn'
    )) = ax.pol_nome

UNION ALL

SELECT 
    -- =============================================
    -- CAMPOS PADRÃO (comum a todas as fatos)
    -- =============================================
    A.EQUIPE AS equipe,
    TO_DATE(A.COMPETENCIA, 'YYYYMM') AS data,
    NVL(f.polo_id, ax.polo_id) AS polo_id,
    d.polo AS polo,
    z.contrato_id AS contrato_id,
    NVL(B.CONTRATO, 'AUSENTE') AS contrato,
    'EQTL_RS' AS empresa,
    e.regional AS regional,
    B.FORNECEDOR AS fornecedor,
    
    -- =============================================
    -- CAMPOS ESPECÍFICOS DA FATO
    -- =============================================
    A.COMPETENCIA,
    TO_NUMBER(SUBSTR(A.COMPETENCIA, 1, 4)) AS ANO,
    TO_NUMBER(SUBSTR(A.COMPETENCIA, 5, 2)) AS MES,
    NULL AS OCORRENCIA_ID,
    NULL AS VERIFICA_HORARIO,
    'QTD_SERV_PROG_FORA_PRAZO_/_QTD_SERV_PROG' AS FORMULA,
    '%' AS UNIDADE

FROM CTE_RS A
LEFT JOIN equipe_contrato B 
    ON A.COMPETENCIA = B.COMPETENCIA 
    AND A.EQUIPE = B.PREFIXO
    AND B.EMPRESA = 'EQTL_RS'
LEFT JOIN {{ ref('dim_equipes') }} c 
    ON A.EQUIPE = c.prefixo 
    AND c.empresa = 'RS'
LEFT JOIN {{ ref('dim_polos') }} d 
    ON c.polo_id = d.cod_polo
LEFT JOIN {{ ref('dim_polos_cosmos') }} f
    ON d.polo = f.pol_nome
LEFT JOIN {{ ref('dim_regionais') }} e 
    ON d.cod_regional = e.cod_regional
LEFT JOIN {{ ref('dim_contratos_cosmos') }} z
    ON B.CONTRATO = z.cod_sap
LEFT JOIN {{ ref('dim_polos_cosmos') }} ax
    ON UPPER(TRANSLATE(
        REPLACE(d.polo, '_', ' '),
        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ',
        'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn'
    )) = ax.pol_nome

{% if is_incremental() %}
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(data, 'YYYYMM') = {{ month_ref }}
    {% endset %}
    {% do run_query(delete_sql) %}
{% endif %}