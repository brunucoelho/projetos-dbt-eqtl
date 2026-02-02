{{ config(materialized='ephemeral') }}

select 
chave_ups,
chave_tmd,
empresa,
regional,
base,
processo,
tipo_serv_executado,
servico,
cast(tme as float) tme,
cast(replace(tmd,'-  ',null) as float) tmd, -- erro no TMD de serviços da LESTE, MATRIZ DE CAMARAGIBE, CORTE MOTO no Alagoas
cast(tma as float) tma,
cast(ups as float) ups
from sb_performance.bronze.tab_ups_2025