{{ config(
    materialized='table'
) }}

SELECT * FROM {{ ref('int_os_merge_oper_al') }}
UNION ALL
SELECT * FROM {{ ref('int_os_merge_siga_al') }}