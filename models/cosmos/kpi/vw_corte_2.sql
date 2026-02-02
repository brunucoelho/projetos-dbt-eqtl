WITH base AS (
SELECT * FROM
(
  SELECT
    CAST(a.dh_execucao_campo AS DATE)        AS dt_ref,
    a.polo_id                                AS polo_id,
    a.contrato_id                            AS contrato_id,
    COUNT(DISTINCT a.nota)                   AS gerados,
    COUNT(DISTINCT CASE
      WHEN a.contrato = a.contrato_atribuicao
       AND TRUNC(a.data, 'MM') = TRUNC(a.dh_execucao_campo, 'MM')
      THEN a.nota
    END)                                     AS executados
  FROM {{ ref('fato_corte_prioridade') }} a
  WHERE a.prioridade = 'P2'
    AND (a.polo_id IS NOT NULL OR a.contrato_id IS NOT NULL)
    
  GROUP BY
    ALL
) WHERE EXECUTADOS <= GERADOS
),

-- Aqui criamos duas variáveis por linha da base
variaveis AS (

  -- Variável EXECUTADOS
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   33,                  -- EXECUTADOS
      'usuarioId',             'F67090761',
      'valor',                 executados,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base

   UNION ALL

  -- Variável GERADOS
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   34,                   -- GERADOS
      'usuarioId',             'F67090761',
      'valor',                 gerados,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base
)

SELECT OBJECT_CONSTRUCT(
  'indicador', OBJECT_CONSTRUCT(
    'id',   12,
    'nome', 'Corte Prioridade 2'
  ),
  'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis