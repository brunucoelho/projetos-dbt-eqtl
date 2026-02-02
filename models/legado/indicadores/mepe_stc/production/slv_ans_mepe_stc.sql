{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_slv_ans_mepe_stc') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE DATE_FROM_PARTS(ANO, MES, 1) = TO_DATE({{ month_ref }}, 'YYYYMM')
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}