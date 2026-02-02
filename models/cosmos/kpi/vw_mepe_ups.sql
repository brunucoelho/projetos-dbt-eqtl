WITH base AS (
    SELECT 
        TO_DATE(dh_competencia, 'YYYYMM') AS data,
        c.polo_id,
        d.contrato_id,
        a.classe_mepe_final
    FROM {{ ref('fato_mepe_ups') }} a
    LEFT JOIN {{ ref('dim_polos') }} b
        ON a.polo = b.polo
    LEFT JOIN {{ ref('dim_polos_cosmos') }} c
        ON b.polo = c.pol_nome
    LEFT JOIN {{ ref('dim_contratos_cosmos') }} d
        ON a.contrato_sap = d.cod_sap      
    WHERE (c.polo_id IS NOT NULL OR d.contrato_id IS NOT NULL)
),

-- agrega qtd por classe
agg AS (
    SELECT
        data,
        polo_id,
        contrato_id,
        classe_mepe_final,
        COUNT(*)::NUMBER AS qtd
    FROM base
    GROUP BY
        data,
        polo_id,
        contrato_id,
        classe_mepe_final
),

-- dimensão com TODAS as classes e seus respectivos IDs de variável
dim_classe AS (
    SELECT 'A' AS classe, 39 AS variavel_indicador_id
    UNION ALL SELECT 'B', 40
    UNION ALL SELECT 'C', 41
    UNION ALL SELECT 'D', 42
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
        AND a.classe_mepe_final = d.classe
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
        'id',   15,
        'nome', 'Desenvolvimento de Equipes - UPS'
    ),
    'variaveis', ARRAY_AGG(variavel)
) AS json_result
FROM variaveis
