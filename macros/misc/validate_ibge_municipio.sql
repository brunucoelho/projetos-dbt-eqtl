{% macro validate_ibge_municipio(cod_municipio, uf=None) %}

{% set _uf_map = {
    'RO': '11', 'AC': '12', 'AM': '13', 'RR': '14',
    'PA': '15', 'AP': '16', 'TO': '17',
    'MA': '21', 'PI': '22', 'CE': '23', 'RN': '24',
    'PB': '25', 'PE': '26', 'AL': '27', 'SE': '28', 'BA': '29',
    'MG': '31', 'ES': '32', 'RJ': '33', 'SP': '35',
    'PR': '41', 'SC': '42', 'RS': '43',
    'MS': '50', 'MT': '51', 'GO': '52', 'DF': '53'
} %}

{% if uf is not none %}
  {% set _uf_literal = uf | replace("'", "") | upper | trim %}
  {% if _uf_literal in _uf_map %}
    {% set _uf_num %}'{{ _uf_map[_uf_literal] }}'{% endset %}
  {% else %}
    {% set _uf_num %}
      CASE UPPER(TRIM(CAST({{ uf }} AS VARCHAR)))
        {% for sigla, codigo in _uf_map.items() %}
        WHEN '{{ sigla }}' THEN '{{ codigo }}'
        {% endfor %}
        ELSE NULL
      END
    {% endset %}
  {% endif %}
{% endif %}

CASE
    WHEN REGEXP_LIKE(CAST({{ cod_municipio }} AS VARCHAR), '^[0-9]{7}$')
        THEN CAST({{ cod_municipio }} AS VARCHAR)
    {% if uf is not none %}
    ELSE ({{ _uf_num }}) || LPAD(CAST({{ cod_municipio }} AS VARCHAR), 5, '0')
    {% else %}
    ELSE NULL
    {% endif %}
END

{% endmacro %}