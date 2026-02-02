WITH base AS (
    SELECT
        a.data,
        a.polo_id,
        a.contrato_id,
        a.classe_mepe_ups,
        NVL(a.realizado_mensal, 0) AS realizado,
        a.dias_uteis
    FROM {{ ref('fato_mepe_ups') }} a
    WHERE (a.polo_id IS NOT NULL OR a.contrato_id IS NOT NULL)
),

-- agrega por classe
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

-- mapeia classes para variavelIndicadorId
dim_classe AS (
    SELECT 'A' AS classe, 43 AS variavel_indicador_id
    UNION ALL SELECT 'B', 44
    UNION ALL SELECT 'C', 45
    UNION ALL SELECT 'D', 46
),

-- gera TODAS as combinações (data, polo, contrato) x (A,B,C,D)
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
       AND a.polo_id = k.polo_id
       AND a.contrato_id = k.contrato_id
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
        'nome', 'MEPE'
    ),
    'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis
