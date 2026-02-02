{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_efic_op_al') }}

UNION ALL

SELECT *
FROM {{ ref('vw_efic_op_ap') }}

UNION ALL

SELECT *
FROM {{ ref('vw_efic_op_go') }}

UNION ALL

SELECT *
FROM {{ ref('vw_efic_op_ma') }}

UNION ALL

SELECT *
FROM {{ ref('vw_efic_op_pa') }}

UNION ALL

SELECT *
FROM {{ ref('vw_efic_op_pi') }}

UNION ALL

SELECT *
FROM {{ ref('vw_efic_op_rs') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_DATE(COMPETENCIA,'YYYYMM') = TO_DATE({{ month_ref }}, 'YYYYMM')
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}