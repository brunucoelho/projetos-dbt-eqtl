{% macro parse_timestamp(timestamp_string) %}
    case
        when {{ timestamp_string }} is null then cast(null as timestamp)

        -- DD/MM/YYYY HH24:MI:SS
        when regexp_like({{ timestamp_string }},
            '^\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2}:\\d{2}$')
        then try_to_timestamp({{ timestamp_string }},
            'DD/MM/YYYY HH24:MI:SS')

        -- DD-MM-YYYY HH24:MI:SS
        when regexp_like({{ timestamp_string }},
            '^\\d{2}-\\d{2}-\\d{4} \\d{2}:\\d{2}:\\d{2}$')
        then try_to_timestamp({{ timestamp_string }},
            'DD-MM-YYYY HH24:MI:SS')

        -- DD/MM/YY HH24:MI:SS
        when regexp_like({{ timestamp_string }},
            '^\\d{2}/\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2}$')
        then try_to_timestamp({{ timestamp_string }},
            'DD/MM/YY HH24:MI:SS')

        -- DD/MM/YY HH24:MI
        when regexp_like({{ timestamp_string }},
            '^\\d{2}/\\d{2}/\\d{2} \\d{2}:\\d{2}$')
        then try_to_timestamp({{ timestamp_string }} || ':00',
            'DD/MM/YY HH24:MI:SS')

        -- DD-MM-YY HH24:MI
        when regexp_like({{ timestamp_string }},
            '^\\d{2}-\\d{2}-\\d{2} \\d{2}:\\d{2}$')
        then try_to_timestamp({{ timestamp_string }} || ':00',
            'DD-MM-YY HH24:MI:SS')

        -- ISO 8601
        when regexp_like({{ timestamp_string }},
            '^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$')
        then try_to_timestamp(replace({{ timestamp_string }}, 'T', ' '),
            'YYYY-MM-DD HH24:MI:SS')

        else null
    end
{% endmacro %}