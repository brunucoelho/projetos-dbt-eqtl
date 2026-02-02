SELECT *
FROM {{ ref('prazo_al') }}

UNION ALL

SELECT *
FROM {{ ref('prazo_ap') }}

UNION ALL

SELECT *
FROM {{ ref('prazo_ma') }}

UNION ALL

SELECT *
FROM {{ ref('prazo_pa') }}

UNION ALL

SELECT *
FROM {{ ref('prazo_pi') }}

UNION ALL

SELECT *
FROM {{ ref('prazo_rs') }}

UNION ALL

SELECT *
FROM {{ ref('prazo_go') }}