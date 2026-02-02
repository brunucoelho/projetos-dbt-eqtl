WITH cte_base AS (
    SELECT 
        um.*,
        CASE 
            WHEN EMPRESA = 'EQTL_GO' 
                 AND REGEXP_LIKE(EQUIPE, '^[A-Za-z]{4}[0-9]{3}[A-Za-z]$') 
                THEN 'GO-' || SUBSTR(EQUIPE, 1, 3) || '-' || SUBSTR(EQUIPE, 4)
            WHEN SUBSTR(EQUIPE,1,3) = SUBSTR(EMPRESA,-2,2)||'-' 
                THEN EQUIPE 
            ELSE SUBSTR(EMPRESA,-2,2)||'-'||EQUIPE
        END AS EQUIPE_CORRIGIDO,
        EXTRACT(YEAR FROM TO_DATE(um.COMPETENCIA ,'YYYYMM')) AS ANO_MEPE,
        EXTRACT(MONTH FROM TO_DATE(um.COMPETENCIA ,'YYYYMM')) AS MES_MEPE,
        um.EMPRESA AS DESC_EMPRESA
    FROM {{ ref('ups_mensal') }} um 
    WHERE CLASSE_MEPE_UPS IS NOT NULL
        AND CLASSE_MEPE_UPS <> ''
        AND TO_DATE(um.COMPETENCIA,'YYYYMM') = TO_DATE({{ get_month_ref() }},'YYYYMM')
),
cte_equipe_contrato AS (
    SELECT *
    FROM cte_base um
    LEFT JOIN (
        SELECT *
        FROM {{ ref('slv_equipe_contrato') }} sec 
        LEFT JOIN SB_PERFORMANCE.EQTL_CORP.SLV_CONTRATOS con 
            ON con.CONTRATO_SAP = sec.CONTRATO 
           AND con.COD_EMPRESA = sec.COD_EMPRESA
        LEFT JOIN SB_PERFORMANCE.SILVER.GLOSSARIO_EMPRESAS ge 
            ON ge.COD_EMPRESA = sec.COD_EMPRESA
    ) A
      ON a.PREFIXO = um.EQUIPE_CORRIGIDO 
     AND a.ANO = um.ANO_MEPE
     AND a.MES = um.MES_MEPE
     AND a.SIGLA_EMPRESA = um.EMPRESA
),

cte_pivot AS (
    SELECT *
    FROM (
        SELECT 
            DESC_EMPRESA AS EMPRESA,
            COALESCE(CONTRATO,'AUSENTE') AS CONTRATO,
            FORNECEDOR_SAP AS FORNECEDOR,
            ANO_MEPE AS ANO,
            MES_MEPE AS MES,
            CLASSE_MEPE_UPS,
            EQUIPE
        FROM cte_equipe_contrato
    )
    PIVOT (
        COUNT(EQUIPE) 
        FOR CLASSE_MEPE_UPS IN ('A','B','C','D')
        DEFAULT ON NULL (0)
    ) AS p (
        EMPRESA,
        CONTRATO,
        FORNECEDOR,
        ANO,
        MES,
        VAR_1_EQUIPES_A,
        VAR_2_EQUIPES_B,
        VAR_3_EQUIPES_C,
        VAR_4_EQUIPES_D
    )
)

SELECT 
    CURRENT_TIMESTAMP AS DATA_ETL,
    EMPRESA,
    '(VAR_1_EQUIPES_A + VAR_2_EQUIPES_B) / (VAR_1_EQUIPES_A + VAR_2_EQUIPES_B + VAR_3_EQUIPES_C + VAR_4_EQUIPES_D)' AS FORMULA,
    c.CONTRATO, 
    c.FORNECEDOR, 
    c.ANO, 
    c.MES, 
    c.VAR_1_EQUIPES_A, 
    c.VAR_2_EQUIPES_B, 
    c.VAR_3_EQUIPES_C, 
    c.VAR_4_EQUIPES_D,
    ROUND(
        (VAR_1_EQUIPES_A + VAR_2_EQUIPES_B) * 1.0 /
        NULLIF((VAR_1_EQUIPES_A + VAR_2_EQUIPES_B + VAR_3_EQUIPES_C + VAR_4_EQUIPES_D),0)
    ,4) AS VALOR,
    '%' AS UNIDADE
FROM cte_pivot c
WHERE EMPRESA IS NOT NULL
  AND CONTRATO IS NOT NULL
  AND ANO IS NOT NULL 
  AND MES IS NOT NULL