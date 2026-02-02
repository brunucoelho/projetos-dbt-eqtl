{% set month_ref = get_month_ref() %}

SELECT *
FROM {{ ref('vw_equipes_horus') }}
WHERE DISTRIBUIDORA <> 'EQTL_GO'

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE VIGENCIA_INICIAL_EQP = TO_DATE({{ month_ref }}, 'YYYYMM')
        AND DISTRIBUIDORA <> 'EQTL_GO'
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}