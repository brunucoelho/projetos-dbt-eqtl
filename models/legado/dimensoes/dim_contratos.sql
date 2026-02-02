{{
  config(
    materialized='table',
    alias='dim_contratos',
    schema='silver',
    tags=['dimension', 'contratos']
  )
}}

select 
A.contrato_sap,
nvl(A.cod_fornecedor, -1) as cod_fornecedor,
A.fornecedor_sap,
A.cod_empresa,
B.sigla_empresa,
SPLIT_PART(B.sigla_empresa, '_', 2) as sigla_empresa_2,
B.empresa,
A.objeto,
A.cod_tipo_contrato
from sb_performance.eqtl_corp.slv_contratos A
left join {{ ref('dim_empresas') }} B
  on A.cod_empresa = B.cod_empresa
left join {{ ref('dim_fornecedores') }} C
  on A.cod_fornecedor = C.cod_fornecedor