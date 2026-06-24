{{
    config(
        materialized='table'
    )
}}

select
    empresa,
--    regional,
--    seccional,
    equipe,
    trunc(data,'MM') competencia,
    sum(case when gerou_retrabalho then 1 else 0 end) notas_retrabalho,
    count(*) notas_total,
    sum(case when gerou_retrabalho then 1 else 0 end) / count(*) perc_retrabalho
from {{ ref('int_retrabalho_global__mepe_equipe') }}
group by all
order by competencia desc