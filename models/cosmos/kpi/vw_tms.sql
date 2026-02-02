WITH base AS (
  SELECT
    CAST(a.dh_ocorrencia AS DATE)     AS dt_ref,
    c.polo_id                         AS polo_id,
    d.contrato_id                     AS contrato_id,
    round(SUM(a.tempo_servico), 6)             AS tempo_apurado,
    round(SUM(a.tempo_medio_servico), 6)       AS tempo_previsto
  FROM {{ ref('fato_tms') }} a
  LEFT JOIN {{ ref('dim_polos') }} b
    ON a.polo = b.polo
  LEFT JOIN {{ ref('dim_polos_cosmos') }} c
    ON b.polo = c.pol_nome
  LEFT JOIN {{ ref('dim_contratos_cosmos') }} d
    ON a.contrato_sap = d.cod_sap
  WHERE (c.polo_id IS NOT NULL OR d.contrato_id IS NOT NULL)
  GROUP BY
    ALL
),

variaveis AS (

  -- VAR_1_TEMPO_APURADO
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   54,  -- <-- AJUSTAR para o ID da variável VAR_1_TEMPO_APURADO
      'usuarioId',             'F67090761',
      'valor',                 tempo_apurado,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base

  UNION ALL

  -- VAR_2_TEMPO_PREVISTO
  SELECT
    OBJECT_CONSTRUCT(
      'poloId',                polo_id,
      'contratoId',            contrato_id,
      'variavelIndicadorId',   55,  -- <-- AJUSTAR para o ID da variável VAR_2_TEMPO_PREVISTO
      'usuarioId',             'F67090761',
      'valor',                 tempo_previsto,
      'data',                  TO_VARCHAR(dt_ref, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
    ) AS variavel
  FROM base
)

SELECT OBJECT_CONSTRUCT(
  'indicador', OBJECT_CONSTRUCT(
    'id',   24,                         -- <-- AJUSTAR para o ID do indicador "Tempo Médio de Serviço"
    'nome', 'Redução Tempo Médio de Serviço'
  ),
  'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis
