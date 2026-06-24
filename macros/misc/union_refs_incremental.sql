{% macro union_refs_incremental(models, unique_keys=[]) %}
    {% for model in models %}
        select src.* from {{ ref(model) }} src
        {% if is_incremental() %}
          left join {{ this }} tgt
            on {% for key in unique_keys %}
                src.{{ key }} = tgt.{{ key }}
                {% if not loop.last %} and {% endif %}
               {% endfor %}
          where tgt.{{ unique_keys[0] }} is null
        {% endif %}
        {% if not loop.last %} union all {% endif %}
    {% endfor %}
{% endmacro %}