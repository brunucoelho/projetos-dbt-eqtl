{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_gp_mepe_retra') }}

UNION ALL

SELECT *
FROM {{ ref('vw_gp_mepe_retra_go') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_DATE(COMPETENCIA,'YYYYMM') = TO_DATE({{ month_ref }}, 'YYYYMM')
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}