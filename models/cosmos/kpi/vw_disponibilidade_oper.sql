WITH base AS (
  SELECT
    CAST(a.data AS DATE)              AS dt_ref,
    a.polo_id                         AS polo_id,
    a.contrato_id                     AS contrato_id,
    NVL(a.tempo_disponivel, 0)        AS tempo_disponivel,
    a.jornada_prevista                AS jornada_prevista
  FROM {{ ref('fato_disponibilidade_oper') }} a
  WHERE a.jornada_prevista IS NOT NULL
    AND a.jornada_prevista <> 0
    AND (a.polo_id IS NOT NULL OR a.contrato_id IS NOT NULL)
    -- Tempo disponível não pode ser maior do que jornada prevista
    AND NVL(a.tempo_disponivel, 0) <= a.jornada_prevista
),

variaveis AS (

  -- Variável: JORNADA PREVISTA
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   1,  -- <-- AJUSTAR para o ID da variável JORNADA PREVISTA
      'usuarioId',             'F67090761',
      'valor',                 jornada_prevista,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base

  UNION ALL

  -- Variável: TEMPO DISPONÍVEL
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   2,  -- <-- AJUSTAR para o ID da variável TEMPO DISPONIVEL
      'usuarioId',             'F67090761',
      'valor',                 tempo_disponivel,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base
)

SELECT OBJECT_CONSTRUCT(
  'indicador', OBJECT_CONSTRUCT(
    'id',   1,                          -- KPI id = 1 (Disponibilidade Operacional)
    'nome', 'DISPONIBILIDADE OPERACIONAL'
  ),
  'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis
