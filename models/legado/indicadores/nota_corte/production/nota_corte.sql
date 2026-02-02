{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_nota_corte_go') }}

UNION ALL

SELECT *
FROM {{ ref('vw_nota_corte_siga') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(DH_ABERTURA, 'YYYYMM') = {{ month_ref }}
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}