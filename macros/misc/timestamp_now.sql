{% macro timestamp_now() %}
    (CONVERT_TIMEZONE(
        'UTC',
        'America/Sao_Paulo',
        CURRENT_TIMESTAMP()
    )::TIMESTAMP_NTZ)
{% endmacro %}