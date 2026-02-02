WITH base AS (
  SELECT
    CAST(data AS DATE)                                         AS dt_ref,
    polo_id                                                    AS polo_id,
    contrato_id                                                AS contrato_id,
    SUM(CASE WHEN estado = 'ADERENTE' THEN 1 ELSE 0 END)       AS escalas_atendidas,
    SUM(CASE
          WHEN estado IN ('ADIANTADO','AUSENTE','ADERENTE','ATRASADO')
          THEN 1 ELSE 0
        END)                                                   AS escalas_totais
  FROM {{ ref('fato_aderencia_escala') }}
  WHERE polo_id IS NOT NULL
    OR contrato_id IS NOT NULL
  GROUP BY
    ALL
),

variaveis AS (

  -- VAR_1_ESCALAS_ATENDIDAS
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   3,  -- <-- AJUSTAR para o ID da variável VAR_1_ESCALAS_ATENDIDAS
      'usuarioId',             'F67090761',
      'valor',                 escalas_atendidas,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base

  UNION ALL

  -- VAR_2_ESCALA
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   4,  -- <-- AJUSTAR para o ID da variável VAR_2_ESCALA
      'usuarioId',             'F67090761',
      'valor',                 escalas_totais,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base
)

SELECT OBJECT_CONSTRUCT(
  'indicador', OBJECT_CONSTRUCT(
    'id',   2,                        -- ID_INDICADOR = 2
    'nome', 'ADERENCIA ESCALA'
  ),
  'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis
