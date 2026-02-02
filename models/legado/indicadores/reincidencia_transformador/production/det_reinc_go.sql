{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_det_reinc_go') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TRUNC(DATA_CONCLUSAO,'MM') = TO_DATE({{ month_ref }}, 'YYYYMM')
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}