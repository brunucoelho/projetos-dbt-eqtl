select
    visita_empresa,
    visita_regional,
    visita_seccional,
    nota_grupo_tipo,
    dt_atividade,
    sum(case when visita_produtiva then 1 else 0 end) primeira_visita,
    count(*) visitas_total
from {{ ref("fct_primeira_visita") }}
group by
    visita_empresa,
    visita_regional,
    visita_seccional,
    nota_grupo_tipo,
    dt_atividade