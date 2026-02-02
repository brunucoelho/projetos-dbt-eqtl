{{
  config(
    materialized = 'incremental',
    on_schema_change = 'sync_all_columns',
    pre_hook = [
      "{% if is_incremental() %} delete from {{ this }} where to_varchar(OCO_DATA_CONCLUSAO,'YYYYMM') = {{ get_month_ref() }} {% endif %}"
    ]
  )
}}

with
-- >>> NENHUM filtro de mês aqui: usa histórico completo <<<
base_full as (
  select *
  from {{ ref('int_os_merge_full_ap') }}
),

filtro_nr as (
  select *
  from base_full
  where OSTIPO = 'NR'
),

transformacao_2 as (
  select v.*
  from base_full v
  inner join SB_PERFORMANCE.EQTL_CORP.CAUSA_RETRABALHO c
    on v.COD_CONCLUSAO = c.RETRABALHO
   and v.COD_SUBCAUSA  = c.SUBCAUSA
   and v.EMPRESA       = c.EMPRESA
),

filtro_exclui_nr as (
  select *
  from base_full
  where OSTIPO <> 'NR'
),

concatenado as (
  select * from transformacao_2
  union all
  select * from filtro_exclui_nr
),

filtro_nr_uc as (
  select *
  from filtro_nr
  where UC >= 1.0
),

resultado_final as (
  select 
      fnr.*,
      c.OCO_DATA_CONCLUSAO  as OCO_DATA_CONCLUSAO_ORIGEM,
      c.OS_OPER              as OS_OPER_ORIGEM,
      c.OS                   as OS_ORIGEM,
      c.OSTIPO               as OSTIPO_ORIGEM,
      c.OSSUBTIPO            as OSSUBTIPO_ORIGEM,
      c.PREFIXO              as PREFIXO_ORIGEM,
      c.COMPONENTE_DANIFICADO as COMPONENTE_DANIFICADO_ORIGEM,
      c.TB_DEFEITO_ID        as TB_DEFEITO_ID_ORIGEM,
      c.TIPO_CONCLUSAO       as TIPO_CONCLUSAO_ORIGEM,
      c.SUBCAUSA             as SUBCAUSA_ORIGEM,
      c.TIPO                 as TIPO_ORIGEM
  from filtro_nr_uc fnr
  inner join concatenado c
    on fnr.EMPRESA = c.EMPRESA
   and fnr.UC      = c.UC
),

resultado_filtrado as (
  select *
  from resultado_final
  where OS_OPER <> OS_OPER_ORIGEM
),

resultado_transformado as (
  select 
    f.*,
    dateadd(day, -90, OCO_DATA_CONCLUSAO) as OCO_DATA_CONCLUSAO90
  from resultado_filtrado f
  where OCO_DATA_CONCLUSAO_ORIGEM <  OCO_DATA_CONCLUSAO
    and OCO_DATA_CONCLUSAO_ORIGEM >= dateadd(day, -90, OCO_DATA_CONCLUSAO)
),

resultado_deduplicado as (
  select *
  from (
    select *,
           row_number() over (
             partition by EMPRESA, OS_OPER
             order by OCO_DATA_CONCLUSAO_ORIGEM desc
           ) as rn
    from resultado_transformado
  ) tmp
  where rn = 1
),

resultado_filtrado_tipo as (
  select *
  from resultado_deduplicado
  where TIPO = 'P'
),

resultado_inner3 as (
  select rft.*
  from resultado_filtrado_tipo rft
  inner join SB_PERFORMANCE.EQTL_CORP.CAUSA_RETRABALHO cr
    on rft.COD_CONCLUSAO = cr.RETRABALHO
   and rft.COD_SUBCAUSA  = cr.SUBCAUSA
   and rft.EMPRESA       = cr.EMPRESA
),

resultado_filtrado_componente as (
  select *
  from resultado_inner3
  where COMPONENTE_DANIFICADO is not null
),

resultado_filtrado_comp_nulo as (
  select *
  from resultado_inner3
  where COMPONENTE_DANIFICADO is null
),

resultado_componente as (
  select rfc.*
  from resultado_filtrado_componente rfc
  inner join SB_PERFORMANCE.EQTL_CORP.COMPONENTE_DANIFICADO cd
    on rfc.COMPONENTE_DANIFICADO = cd.COMPONENTE_DANIFICADO
),

resultado_conc_comp as (
  select * from resultado_componente
  union all
  select * from resultado_filtrado_comp_nulo
),

resultado_nom_row_filter as (
  select *
  from resultado_conc_comp
  where ABRANGENCIA = 'CONSUMIDOR'
),

resultado_left_final as (
  select
      fr.*,
      rf.OCO_DATA_CONCLUSAO_ORIGEM,
      rf.OS_OPER_ORIGEM,
      rf.OS_ORIGEM,
      rf.OSTIPO_ORIGEM,
      rf.OSSUBTIPO_ORIGEM,
      rf.PREFIXO_ORIGEM,
      rf.TIPO_CONCLUSAO_ORIGEM,
      rf.SUBCAUSA_ORIGEM,
      rf.TIPO_ORIGEM
  from filtro_nr fr 
  left join resultado_nom_row_filter rf 
    on rf.EMPRESA = fr.EMPRESA 
   and rf.OS_OPER = fr.OS_OPER
),

resultado_duplicate_final as (
  select *
  from (
    select *,
           row_number() over (
             partition by EMPRESA, OCO_DATA_CONCLUSAO, OS_OPER, OS
             order by OCO_DATA_CONCLUSAO_ORIGEM desc
           ) as rn
    from resultado_left_final
  ) tmp
  where rn = 1
)

-- >>> Só aqui filtramos a competência para ir à tabela final <<<
select f.* EXCLUDE(RN)
from resultado_duplicate_final f
{% if is_incremental() %}
  where to_varchar(OCO_DATA_CONCLUSAO,'YYYYMM') = {{ get_month_ref() }}
{% endif %}
