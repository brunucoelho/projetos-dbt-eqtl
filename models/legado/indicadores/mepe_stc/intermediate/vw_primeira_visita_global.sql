SELECT *
FROM {{ ref('primeira_visita_al') }}

UNION ALL

SELECT *
FROM {{ ref('primeira_visita_ma') }}

UNION ALL

SELECT *
FROM {{ ref('primeira_visita_pa') }}

UNION ALL

SELECT *
FROM {{ ref('primeira_visita_pi') }}