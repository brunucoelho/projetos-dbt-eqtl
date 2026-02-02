WITH base AS (
  SELECT
    CAST(a.dh_execucao_campo AS DATE)                                      AS dt_ref,
    a.polo_id                                                              AS polo_id,
    a.contrato_id                                                          AS contrato_id,
    COUNT(DISTINCT CASE WHEN a.tipo = 'RELIGA' THEN a.nota ELSE NULL END)  AS religas,
    COUNT(DISTINCT CASE WHEN a.tipo = 'CORTE'  THEN a.nota ELSE NULL END)  AS cortes
  FROM {{ ref('fato_religa_vinculada') }} a
  WHERE (a.polo_id IS NOT NULL OR a.contrato_id IS NOT NULL)
  GROUP BY
    ALL
),

variaveis AS (

  -- VAR_1_RELIGAS
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   37,  -- <-- AJUSTAR para o ID da variável VAR_1_RELIGAS
      'usuarioId',             'F67090761',
      'valor',                 religas,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base

  UNION ALL

  -- VAR_2_CORTES
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   38,  -- <-- AJUSTAR para o ID da variável VAR_2_CORTES
      'usuarioId',             'F67090761',
      'valor',                 cortes,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base
)

SELECT OBJECT_CONSTRUCT(
  'indicador', OBJECT_CONSTRUCT(
    'id',   17,                 -- <-- AJUSTAR para o ID do indicador (Religa/Corte, etc.)
    'nome', 'Religa Vinculada'
  ),
  'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis
