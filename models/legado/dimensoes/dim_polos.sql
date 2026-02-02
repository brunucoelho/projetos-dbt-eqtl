{{
  config(
    materialized='table',
    alias='dim_polos',
    schema='silver',
    tags=['dimension', 'polos']
  )
}}

select 
  A.cod_polo,
  A.cod_regional,
  UPPER(TRANSLATE(
    REPLACE(A.polo, '_', ' '),
    'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ',
    'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn'
  )) as polo,
  B.regional,
  B.cod_empresa,
  C.empresa,
  C.sigla_empresa
from sb_performance.silver.glossario_polos A
left join {{ ref('dim_regionais') }} B
  on A.cod_regional = B.cod_regional
left join {{ ref('dim_empresas') }} C
  on B.cod_empresa = C.cod_empresa