{{
    config(
        materialized='table'
    )
}}

select
    visita_empresa,
--    visita_regional,
--    visita_seccional,
    trunc(dh_fim_servico,'MM') mes_ano,
    equipe,
    sum(case when visita_produtiva then 1 else 0 end) primeira_visita,
    count(*) visitas,
    primeira_visita / visitas aderencia_primeira_visita
from {{ ref('fct_primeira_visita') }}
where nota_grupo_tipo in ('[RL] - Religação','[LN] - Ligação Nova','[OC] - Orçamento de Conexão BT')
group by all