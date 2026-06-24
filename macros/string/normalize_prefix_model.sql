{% macro normalize_prefix_model(column_name, uf_expr) %}
    CASE

        WHEN REGEXP_LIKE(
            {{ column_name }},
            '^[A-Z]{2}_[A-Z]{2}-[A-Z]{3}-[A-Z]{1}[0-9]{3}[A-Z]{1}$'
        ) THEN
            REGEXP_REPLACE(
                {{ column_name }},
                '^[A-Z]{2}_([A-Z]{2}-[A-Z]{3}-[A-Z]{1}[0-9]{3}[A-Z]{1})$',
                '\\1'
            )           

        WHEN REGEXP_LIKE(
            {{ column_name }},
            '^[A-Z]{2}_[A-Z]{3}-[A-Z]{1}[0-9]{3}[A-Z]{1}$'
        ) THEN
            {{ uf_expr }} || '-' ||
            REGEXP_REPLACE(
                {{ column_name }},
                '^[A-Z]{2}_([A-Z]{3}-[A-Z]{1}[0-9]{3}[A-Z]{1})$',
                '\\1'
            ) 

        WHEN REGEXP_LIKE(
            {{ column_name }},
            '^[A-Z]{4}[0-9]{3}[A-Z]$'
        ) THEN
            {{ uf_expr }} || '-' ||
            REGEXP_REPLACE(
                {{ column_name }},
                '^([A-Z]{3})([A-Z][0-9]{3}[A-Z])$',
                '\\1-\\2'
            )

        WHEN REGEXP_LIKE(
            {{ column_name }},
            '^[A-Z]{3}-[A-Z]{1}[0-9]{3}[A-Z]{1}$'
        ) THEN
            {{ uf_expr }} || '-' || {{ column_name }}

        WHEN REGEXP_LIKE(
            {{ column_name }},
            '^[A-Z]{2}_\S+$'
        ) THEN
            {{ uf_expr }} || '-' || 
            REGEXP_REPLACE(
                {{ column_name }},
                '^[A-Z]{2}_(\S+)$',
                '\\1'
            )
        
        ELSE {{ column_name }}
    END
{% endmacro %}