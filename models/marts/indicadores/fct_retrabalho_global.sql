{{
    config(
        materialized='view'
    )
}}

{{ dbt_utils.union_relations(
    relations=[
        ref('int_retrabalho_global__al'),
        ref('int_retrabalho_global__ap'),
        ref('int_retrabalho_global__go'),
        ref('int_retrabalho_global__ma'),
        ref('int_retrabalho_global__pa'),
        ref('int_retrabalho_global__pi'),
        ref('int_retrabalho_global__rs'),
        ],
    exclude=["_loaded_at"]
) }}