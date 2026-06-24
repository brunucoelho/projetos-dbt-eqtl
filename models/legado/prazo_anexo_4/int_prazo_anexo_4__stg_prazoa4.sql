{% macro create_prazoa4_views() %}

    {% set empresas = [
        {'empresa': 'EQTL_AL', 'alias': 'STG_PRAZOA4_AP', 'schema': 'EQTL_AL'},
        {'empresa': 'EQTL_AP', 'alias': 'STG_PRAZOA4',    'schema': 'EQTL_AP'},
        {'empresa': 'EQTL_MA', 'alias': 'STG_PRAZOA4',    'schema': 'EQTL_MA'},
        {'empresa': 'EQTL_PA', 'alias': 'STG_PRAZOA4',    'schema': 'EQTL_PA'},
        {'empresa': 'EQTL_PI', 'alias': 'STG_PRAZOA4',    'schema': 'EQTL_PI'},
        {'empresa': 'EQTL_RS', 'alias': 'STG_PRAZOA4',    'schema': 'EQTL_RS'}
    ] %}

    {% for item in empresas %}

        {% set query %}
            create or replace view {{ item.schema }}.{{ item.alias }} as
            select *
            from {{ ref('fct_prazo_anexo_4_sap') }}
            where empresa = '{{ item.empresa }}'
        {% endset %}

        {% do run_query(query) %}

    {% endfor %}

{% endmacro %}