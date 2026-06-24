{{
    config(
        materialized='table'
    )
}}

with visita_prazo as (
    {{ dbt_utils.union_relations(
    relations=[
        ref('int_prazo_anexo_4__al_visitas'),
        ref('int_prazo_anexo_4__ap_visitas'),
        ref('int_prazo_anexo_4__ma_visitas'),
        ref('int_prazo_anexo_4__pa_visitas'),
        ref('int_prazo_anexo_4__pi_visitas'),
        ref('int_prazo_anexo_4__rs_visitas'),
        ],
    exclude=["_loaded_at"]
    ) }}
)

select
    empresa,
--    regional,
--    seccional,
    equipe_execucao,
    trunc(data_final_servico,'MM') competencia,
    sum(case when status_prazo = 'DENTRO DO PRAZO' then 1 else 0 end) notas_dentro_prazo,
    sum(case when status_prazo = 'FORA DO PRAZO' then 1 else 0 end) notas_fora_prazo,
    NULLIF(notas_dentro_prazo + notas_fora_prazo,0) notas_total,
    sum(case when status_prazo = 'DENTRO DO PRAZO' then 1 else 0 end) / notas_total aderencia_prazo
from visita_prazo
where responsabilidade = 'GESTAO SERV REDE'
    and data_final_servico is not null
group by all

union all 

select * from {{ ref('int_prazo_anexo_4__rs_visitas_2025') }}