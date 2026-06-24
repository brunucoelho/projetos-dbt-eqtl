{{
    config(
        materialized='view'
    )
}}

{{ dbt_utils.union_relations(
    relations=[
        ref('int_reincidencia_transformador__go'),
        ref('int_reincidencia_transformador__mapapialrs'),
        ],
    exclude=["_loaded_at"]
) }}