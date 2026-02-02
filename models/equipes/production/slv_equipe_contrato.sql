{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_slv_equipe_contrato_sgt') }}

UNION ALL

SELECT *
FROM {{ ref('vw_slv_equipe_contrato_horus') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE ANO = YEAR(TO_DATE({{ month_ref }}, 'YYYYMM'))
        AND MES = MONTH(TO_DATE({{ month_ref }}, 'YYYYMM'))
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}