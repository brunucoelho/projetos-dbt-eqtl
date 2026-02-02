{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_serv_exec_detalhado_siga') }}

UNION ALL 

SELECT *
FROM {{ ref('vw_serv_exec_detalhado_oper_go') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(DATA_CONCLUSAO, 'YYYYMM') = {{ month_ref }}
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}