{{config(
    materialized='table'
)}}

with base as (
    select *,
    right(empresa,2) uf
    from {{ ref("fct_reincidencia_transformador") }}
)

select 
    replace(atendimentos.empresa,' ','_') empresa,
    atendimentos.regional,
    atendimentos.seccional,
    atendimentos.data,
    {{ normalize_prefix_model('atendimentos.prx_descricao','atendimentos.uf') }} equipe,
    atendimentos.data_conclusao,
    atendimentos.natureza,
    atendimentos.perimetro,
    atendimentos.ocorrencia,
    atendimentos.causa,

    reincidencias.ocorrencia reinc_gerado_ocorrencia,
    {{ normalize_prefix_model('reincidencias.prx_descricao','atendimentos.uf') }} reinc_gerado_equipe,
    reincidencias.data_conclusao reinc_gerado_data_conclusao
from base atendimentos
left join base reincidencias
    on atendimentos.empresa = reincidencias.empresa
    and atendimentos.ocorrencia = reincidencias.ocorrencia_anterior
    and reincidencias.clie > 1
    and reincidencias.reincidente_90_dias = 'S'