WITH base AS (
  SELECT
    CAST(a.data AS DATE)                  AS dt_ref,
    a.polo_id                             AS polo_id,
    a.contrato_id                         AS contrato_id,
    COUNT(*) - SUM(a.DEMANDOU_APOIO)      AS ocorrencia_1_visita,
    COUNT(*)                              AS total_ocorrencia
  FROM {{ ref('fato_primeira_visita') }} a
  WHERE (a.polo_id IS NOT NULL OR a.contrato_id IS NOT NULL)
  GROUP BY
    ALL
),

variaveis AS (

  -- VAR_1_OCORRENCIA_1_VISITA
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   101,  -- <-- ajuste para o ID correto dessa variável
      'usuarioId',             'F67090761',
      'valor',                 ocorrencia_1_visita,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base

  UNION ALL

  -- VAR_2_TOTAL_OCORRENCIA
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   102,  -- <-- ajuste para o ID correto dessa variável
      'usuarioId',             'F67090761',
      'valor',                 total_ocorrencia,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base
)

SELECT OBJECT_CONSTRUCT(
  'indicador', OBJECT_CONSTRUCT(
    'id',   20,                       -- <-- ajuste para o ID do indicador
    'nome', 'Primeira Visita'         -- <-- ajuste o nome se precisar
  ),
  'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis
