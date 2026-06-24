{{
    config(
        materialized='view'
    )
}}

{{ dbt_utils.union_relations(
    relations=[
        ref('int_prazo_anexo_4__al'),
        ref('int_prazo_anexo_4__ap'),
        ref('int_prazo_anexo_4__ma'),
        ref('int_prazo_anexo_4__pa'),
        ref('int_prazo_anexo_4__pi'),
        ref('int_prazo_anexo_4__rs'),
        ],
    exclude=["_loaded_at"]
) }}