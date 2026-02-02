WITH base AS (
    SELECT 
        TO_DATE(competencia, 'YYYYMM') AS data,
        polo_id,
        contrato_id,
        classe_mepe_ups
    FROM {{ ref('fato_mepe_comercial') }}
    WHERE polo_id IS NOT NULL 
      OR contrato_id IS NOT NULL
),

-- agrega qtd por classe
agg AS (
    SELECT
        data,
        polo_id,
        contrato_id,
        classe_mepe_ups,
        COUNT(*)::NUMBER AS qtd
    FROM base
    GROUP BY
        data,
        polo_id,
        contrato_id,
        classe_mepe_ups
),

-- dimensão com TODAS as classes e seus respectivos IDs de variável
dim_classe AS (
    SELECT 'A' AS classe, 43 AS variavel_indicador_id
    UNION ALL SELECT 'B', 44
    UNION ALL SELECT 'C', 45
    UNION ALL SELECT 'D', 46
),

-- gera todas as combinações data/polo/contrato x classes A,B,C,D
comb AS (
    SELECT
        k.data,
        k.polo_id,
        k.contrato_id,
        d.classe,
        d.variavel_indicador_id,
        COALESCE(a.qtd, 0) AS valor
    FROM (
        SELECT DISTINCT
            data,
            polo_id,
            contrato_id
        FROM base
    ) k
    CROSS JOIN dim_classe d
    LEFT JOIN agg a
        ON a.data = k.data
       AND nvl(a.polo_id, 0) = nvl(k.polo_id, 0)
       AND nvl(a.contrato_id, 0) = nvl(k.contrato_id, 0)
       AND a.classe_mepe_ups = d.classe
),

variaveis AS (
    SELECT
        OBJECT_CONSTRUCT(
            'poloId',              polo_id,
            'contratoId',          contrato_id,
            'variavelIndicadorId', variavel_indicador_id,
            'usuarioId',           'F67090761',
            'valor',               valor,
            'data',                TO_VARCHAR(data, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"')
        ) AS variavel
    FROM comb
)

SELECT OBJECT_CONSTRUCT(
    'indicador', OBJECT_CONSTRUCT(
        'id',   16,
        'nome', 'Desenvolvimento de Equipes - Comercial'
    ),
    'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis
