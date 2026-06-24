{{
    config(
        materialized='table'
    )
}}

with base as (
    select *
    from {{ ref("fct_reincidencia_transformador") }}
)
,

notas as (
select 
    right(atendimentos.empresa,2) uf,
    replace(atendimentos.empresa,' ','_') empresa,
    atendimentos.regional,
    atendimentos.seccional,
    atendimentos.data,
    atendimentos.prx_descricao,
    atendimentos.data_conclusao,
    atendimentos.natureza,
    atendimentos.perimetro,
    atendimentos.ocorrencia,
    atendimentos.causa,
    atendimentos.abrangencia,
    atendimentos.pdf,
    atendimentos.tipo_eqp,
    atendimentos.potencia,

    reincidencias.ocorrencia reinc_gerado_ocorrencia,
    reincidencias.prx_descricao reinc_gerado_prx_descricao,
    reincidencias.data_conclusao reinc_gerado_data_conclusao
from base atendimentos
left join base reincidencias
    on atendimentos.ocorrencia = reincidencias.ocorrencia_anterior
    and reincidencias.clie > 1
    and reincidencias.reincidente_90_dias = 'S'
)

select
    empresa,
--    regional,
--    seccional,
    {{ normalize_prefix_model('prx_descricao','uf') }} equipe,
    trunc(data, 'MM') competencia,
    COALESCE(count(reinc_gerado_ocorrencia), 0) notas_reincidentes,
    count(*) notas_total,
    notas_reincidentes / notas_total perc_reincidente
    from notas
    group by all