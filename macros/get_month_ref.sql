{% macro get_month_ref() %}
    {% if var('month_ref', None) %}
        {% set month = var("month_ref") %}
    {% else %}
        {% set today = modules.datetime.datetime.today() %}

        {% if today.day < 10 %}
            {% set ref_date = today.replace(day=1) - modules.datetime.timedelta(days=1) %}
        {% else %}
            {% set ref_date = today.replace(day=1) %}
        {% endif %}

        {% set month = ref_date.strftime("%Y%m") %}
    {% endif %}

    {{ log(">>> Using month_ref = " ~ month, info=True) }}

    '{{ month }}'
{% endmacro %}
