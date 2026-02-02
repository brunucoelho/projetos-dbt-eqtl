{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_programadas_al') }}

UNION ALL

SELECT *
FROM {{ ref('vw_programadas_ap') }}

UNION ALL

SELECT *
FROM {{ ref('vw_programadas_ma') }}

UNION ALL

SELECT *
FROM {{ ref('vw_programadas_pa') }}

UNION ALL

SELECT *
FROM {{ ref('vw_programadas_pi') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(INICIO_PREVISTO, 'YYYYMM') = {{ month_ref }}
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}