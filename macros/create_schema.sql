{% macro create_schema(relation) -%}
  {%- call statement('create_schema') -%}
    -- Schema já existe no Snowflake, não precisa criar
    -- Esta macro sobrescreve o comportamento padrão do DBT
    SELECT 1
  {%- endcall -%}
{% endmacro %}

