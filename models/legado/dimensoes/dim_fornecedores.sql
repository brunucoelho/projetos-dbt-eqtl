{{
  config(
    materialized='table',
    alias='dim_fornecedores',
    schema='silver',
    tags=['dimension', 'fornecedores']
  )
}}

select 
  distinct nvl(cod_fornecedor, -1) as cod_fornecedor, 
  fornecedor_sap 
from sb_performance.eqtl_corp.slv_contratos