{{
    config(
        materialized = 'incremental',
        unique_key = '_dbt_unique_key',
        incremental_strategy='merge'
    )
}}

with base as (
    select 
    *
    from {{ ref('int_primeira_visita__union') }}
)

select * from base