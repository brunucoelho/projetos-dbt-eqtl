{{
  config(
    materialized='table',
    alias='dim_regionais',
    schema='silver',
    tags=['dimension', 'regionais']
  )
}}

select * from sb_performance.silver.glossario_regionais