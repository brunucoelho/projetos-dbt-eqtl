{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_programadas_go') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(INICIO_PREVISTO, 'YYYYMM') = {{ month_ref }}
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}