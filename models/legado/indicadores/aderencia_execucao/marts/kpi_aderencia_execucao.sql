{{
  config(
    materialized = 'incremental',
    schema = 'gold',
    unique_key = ['EMPRESA', 'REGIONAL', 'CONTRATO', 'PROCESSO', 'ANO', 'MES'],
    on_schema_change = 'sync_all_columns',
    tags=['aderencia_execucao', 'kpi', 'gold'],
    pre_hook = [
      "{% if is_incremental() %} 
        delete from {{ this }} 
        where {{ this }}.ANO || LPAD({{ this }}.MES::STRING, 2, '0') = {{ get_month_ref() }} 
      {% endif %}"
    ]
  )
}}


WITH DIMEMPREITEIRA_TRATADO AS (
    SELECT 
        DE.*,
        TRIM(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_SUBSTR(EMPRETEIRA, '\\(([^)]+)\\)', 1, 1, 'e'),
                    '[()]', ''
                ),
                '^.*-', ''
            )
        ) AS PROCESSO
    FROM {{ ref('int_dimempreiteira') }} DE
),
FPROGRAMACAO_TRATADO AS (
    SELECT 
        FP.*,
        CASE 
            WHEN FP.PROGRAMACAO_EXECUTADA2 IN ('SIM', 'OBRA CANCELADA', 'PARCIALMENTE', 'REPROGRAMADA') THEN
                CASE 
                    WHEN CAL.COMPETENCIA = 202529 THEN 
                        CASE 
                            WHEN FP.DATA_ALTERACAO > TO_DATE('2025-07-25', 'YYYY-MM-DD') 
                            THEN 'FORA DA JANELA'
                            ELSE 'DENTRO DA JANELA'
                        END
                    ELSE
                        CASE 
                            WHEN FP.DATA_ALTERACAO > DATEADD(
                                DAY, 
                                3, 
                                DATEADD(
                                    DAY, 
                                    (7 - DAYOFWEEKISO(FP.DATA_PROGRAMACAO_EXECUCAO) + 1), 
                                    FP.DATA_PROGRAMACAO_EXECUCAO
                                )
                            )
                            THEN 'FORA DA JANELA'
                            ELSE 'DENTRO DA JANELA'
                        END
                END
            ELSE NULL
        END AS APONTAMENTO_EXECUCAO
    FROM {{ ref('int_fprogamacao') }} FP
    LEFT JOIN SB_PERFORMANCE.EQTL_CORP.SIPROG_OURO__VIEW__DIM_TEMPO CAL 
           ON CAL.DATA = FP.DATA_PROGRAMACAO_EXECUCAO
)
SELECT 
    E.EMPRESA,
    E.REGIONAL,
    E.CONTRATO,
    E.PROCESSO,
    'ADERENCIA DA PROGRAMACAO' AS INDICADOR,
    C.ANO_COMPETENCIA AS ANO,
    C.N_MES_COMPETENCIA AS MES,
    '%' AS UNIDADE,
    'MAIOR MELHOR' AS POLARIDADE,
    -- Numerador
    SUM(CASE 
            WHEN F.PROGRAMACAO_EXECUTADA2 = 'SIM' 
                 AND F.APONTAMENTO_EXECUCAO = 'DENTRO DA JANELA' 
            THEN 1 ELSE 0 
        END) AS EXECUTADO,
    -- Denominador
    SUM(CASE 
            WHEN F.PROGRAMACAO_EXECUTADA2 IN ('SIM', 'REPROGRAMADA', 'PARCIALMENTE', 'OBRA CANCELADA') 
                 OR F.PROGRAMACAO_EXECUTADA2 IS NULL 
            THEN 1 ELSE 0 
        END) AS PROGRAMADO,
    -- Percentual
    ROUND(
        (
            SUM(CASE 
                    WHEN F.PROGRAMACAO_EXECUTADA2 = 'SIM' 
                         AND F.APONTAMENTO_EXECUCAO = 'DENTRO DA JANELA' 
                    THEN 1 ELSE 0 
                END) * 100.0
        ) / NULLIF(
            SUM(CASE 
                    WHEN F.PROGRAMACAO_EXECUTADA2 IN ('SIM', 'REPROGRAMADA', 'PARCIALMENTE', 'OBRA CANCELADA') 
                         OR F.PROGRAMACAO_EXECUTADA2 IS NULL 
                    THEN 1 ELSE 0 
                END), 
            0
        ), 
    1)::FLOAT AS ADERENCIA
FROM FPROGRAMACAO_TRATADO F
LEFT JOIN {{ ref('int_fequipes') }} FE
    ON F.IDEQUIPE = FE.ID_EQUIPE
LEFT JOIN DIMEMPREITEIRA_TRATADO E
    ON FE.ID_EMPRETEIRA = E.IDEMPRETEIRA
LEFT JOIN SB_PERFORMANCE.EQTL_CORP.SIPROG_OURO__VIEW__DIM_TEMPO C
    ON F.DATA_PROGRAMACAO_EXECUCAO = C.DATA
 {% if is_incremental() %}
  where C.ANO_COMPETENCIA || LPAD(C.N_MES_COMPETENCIA::STRING, 2, '0')  = {{ get_month_ref() }}
{% endif %}
GROUP BY 
ALL

