{{
  config(
    materialized='table',
    alias='dim_empresas',
    schema='silver',
    tags=['dimension', 'empresas']
  )
}}

select * from sb_performance.silver.glossario_empresas