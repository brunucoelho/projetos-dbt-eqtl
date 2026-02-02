{{ config(
    materialized='table'
) }}


SELECT * FROM {{ ref('int_os_emergencial_siga_al') }}
UNION ALL
SELECT * FROM {{ ref('int_os_comercial_siga_al') }}