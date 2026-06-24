{{
    config(
        materialized = 'table'
    )
}}


with

equipe_cosmos as (
    select 
    * exclude(rn) 
    from (
    select 
        equipe.equipe,
        empresa.empresa,
        regional.regional,
        polo.polo,
        row_number() over (partition by equipe_id order by valido_de desc) rn
    from bd_cosmos.public.dim_equipes_scd2_mensal equipe
    left join bd_cosmos.public.dim_empresas empresa
        on empresa.empresa_id = equipe.empresa_id
    left join bd_cosmos.public.dim_regionais regional
        on regional.regional_id = equipe.regional_id
    left join bd_cosmos.public.dim_polos polo
        on polo.polo_id = equipe.polo_id
    where equipe.polo_id is not null
    )
    where rn = 1
),

base as (
    select 
    *,
    replace(split(empresa,'_')[1],'"','') UF
    from {{ ref("resultado_mepe") }}
    where left(competencia,4) = '2025'
        or left(competencia,4) = '2026'
),

normalizar_equipe as (
    select
    * exclude(equipe),
    {{ normalize_prefix_model('EQUIPE', 'UF') }} equipe
    from base
),

normalizar_regional_polo as (
    select
        equipe.*,
        cosmos.regional regional_cosmos,
        cosmos.polo polo_cosmos
    from normalizar_equipe equipe
    left join equipe_cosmos cosmos
        on equipe.empresa = cosmos.empresa
        and equipe.equipe = cosmos.equipe

),

normalizar_tipo_equipe as (
    select
    *,
    CASE
        when {{ is_valid_prefix_model('equipe') }} then replace(left(split(equipe,'-')[2],1),'"','')
        else null
    end as sigla_processo
    from normalizar_regional_polo
),

retrabalho_unificado as (
    select
    * exclude(competencia),
    to_char(competencia, 'YYYYMM') competencia
    from sb_servicos_rede.public.fct_mepe_retrabalho
),

retrabalho_global as (
select 
    equipe.* 
    exclude(
        mepe_retra,
        aderencia_retrabalho,
        classe_mepe_retrabalho,
        qtd_ori_retr_com,
        qtd_total_retr_com,
        perc_retra_com,
        meta_retr_com,
        aderencia_retr_com,
        classe_mepe_retr_com,
        mepe_retr_com,
        perc_retra
        ),
    retrabalho.notas_total qtd_total,
    retrabalho.notas_retrabalho qtd_retra,
    retrabalho.perc_retrabalho perc_retra
    from normalizar_tipo_equipe equipe
    left join retrabalho_unificado retrabalho
        on retrabalho.equipe = equipe.equipe
        and to_date(retrabalho.competencia, 'YYYYMM') = DATEADD(month, -3,to_date(equipe.competencia,'YYYYMM'))
        and retrabalho.empresa = equipe.empresa
),

primeira_visita_base as (
    select
    visita_empresa,
    mes_ano,
    equipe,
    primeira_visita,
    visitas,
    aderencia_primeira_visita perc_prim_novo
    from sb_servicos_rede.public.fct_mepe_primeira_visita
),

primeira_visita as (
    select 
    a.*,
    prim.primeira_visita visitas_primeira,
    prim.visitas,
    prim.perc_prim_novo
    from retrabalho_global a
    left join primeira_visita_base prim 
        on prim.visita_empresa = a.empresa
        and prim.mes_ano = to_date(a.competencia,'YYYYMM')
        and prim.equipe = a.equipe
),

reincidencia_base as (
    select
    empresa,
    equipe,
    competencia,
    notas_reincidentes qtd_reincidentes,
    notas_total reincidente_total,
    perc_reincidente reincidente_perc
    from sb_servicos_rede.public.fct_mepe_reincidencia_transformador
),

reincidencia as (
    select a.* exclude(qtd_reincidentes),
    reinc.qtd_reincidentes,
    reinc.reincidente_total,
    reinc.reincidente_perc
    from primeira_visita a
    left join reincidencia_base reinc
        on reinc.empresa = a.empresa
        and reinc.competencia = DATEADD(month, -3,to_date(a.competencia,'YYYYMM'))
        and reinc.equipe = a.equipe
),

prazo_base as (
    select
    empresa,
    equipe_execucao,
    competencia,
    notas_dentro_prazo,
    notas_fora_prazo,
    notas_total,
    aderencia_prazo perc_prazo
    from sb_servicos_rede.public.fct_mepe_prazo
),

prazo as (
    select a.* exclude(perc_prazo),
    prazo.notas_dentro_prazo prazo_dentro,
    prazo.notas_total prazo_total,
    prazo.perc_prazo
    from reincidencia a
    left join prazo_base prazo
        on prazo.empresa = a.empresa
        and prazo.competencia = to_date(a.competencia,'YYYYMM')
        and prazo.equipe_execucao = a.equipe
),

meta_2026 as (
    select
    a.* exclude(meta_prazo),
    b.* exclude (empresa, regional, polo),
    b.reincidencia_transformador meta_reincidente,
    b.retrabalho meta_retrabalho,
    b.prazo meta_prazo,
    b.primeira_visita meta_primeira_visita
    from prazo a
    left join {{ ref('metas_mepe_2026') }} b
        on a.empresa = b.empresa
        and a.regional_cosmos = b.regional
        and a.polo_cosmos = b.polo
),

colunas_relevantes as (
    select
    empresa,
    regional_cosmos regional,
    polo_cosmos polo,
    sigla_processo,
    equipe,
    to_date(competencia,'YYYYMM') competencia,

    -- UPS
    realizado_mensal ups_realizado,
    dias_uteis ups_dias,
    media_ups_mes ups_media,
    nullif(meta_mensal,0) ups_meta,
    

    -- PRAZO
    coalesce(prazo_dentro,0) prazo_dentro,
    coalesce(prazo_total,0) prazo_total,
    perc_prazo prazo_perc,
    nullif(meta_prazo,0) meta_prazo,

    -- PRIMEIRA VISITA
    coalesce(visitas_primeira,0) primeira_visita,
    coalesce(visitas,0) visitas,
    perc_prim_novo primeira_visita_perc,
    nullif(meta_primeira_visita,0) meta_primeira_visita,

    -- REINCIDENTE
    coalesce(qtd_reincidentes,0) reincidente,
    coalesce(reincidente_total,0) reincidente_total,
    coalesce(reincidente_perc,0) reincidente_perc,
    nullif(meta_reincidente,0) meta_reincidente,

    -- RETRABALHO
    coalesce(qtd_retra,0) retrabalho,
    coalesce(qtd_total,0) retrabalho_total,
    perc_retra retrabalho_perc,
    nullif(meta_retrabalho,0) meta_retrabalho

    from meta_2026
),

selecao_equipes as (
    select * from colunas_relevantes
    where sigla_processo in ('E','L','M','R','C','H')
),

classes as (
    select 
    *,

    round(
    case 
        when div0null(ups_realizado, ups_meta)*100 > 100 then 100
        else div0null(ups_realizado, ups_meta)*100
    end,2) as mepe_ups,

    case 
        when prazo_total = 0 then null
        when div0null(prazo_perc , meta_prazo) >= 1.00 then 100
        when div0null(prazo_perc , meta_prazo) >= 0.98 then 70
        when div0null(prazo_perc , meta_prazo) >= 0.96 then 30
        when div0null(prazo_perc , meta_prazo) < 0.96 then 0
        else 100
    end as mepe_prazo,  

    case 
        when visitas = 0 then null
        when div0null(primeira_visita_perc , meta_primeira_visita) >= 1.00 then 100
        when div0null(primeira_visita_perc , meta_primeira_visita) >= 0.95 then 70
        when div0null(primeira_visita_perc , meta_primeira_visita) >= 0.90 then 30
        when div0null(primeira_visita_perc , meta_primeira_visita) < 0.90 then 0
        else 100
    end as mepe_prim_vis,  

    case 
        when reincidente_total = 0 then null
        when div0null(reincidente_perc , meta_reincidente) >= 1.50 then 0
        when div0null(reincidente_perc , meta_reincidente) >= 1.30 then 30
        when div0null(reincidente_perc , meta_reincidente) >= 1.10 then 70
        when div0null(reincidente_perc , meta_reincidente) < 1.10 then 100
        else 100
    end as mepe_reinc,

    case 
        when retrabalho_total = 0 then null
        when div0null(retrabalho_perc, meta_retrabalho) > 1.00 then 0
        when div0null(retrabalho_perc, meta_retrabalho) > 0.80 then 30
        when div0null(retrabalho_perc, meta_retrabalho) > 0.60 then 70
        when div0null(retrabalho_perc, meta_retrabalho) <= 0.60 then 100
        else 100
    end as mepe_retrabalho,

    from colunas_relevantes
),

mepe as (
    select *,

    round(
        (
            COALESCE(mepe_ups, 0)        * CASE WHEN mepe_ups        IS NOT NULL THEN 1 ELSE 0 END
        + COALESCE(mepe_prazo, 0)      * CASE WHEN mepe_prazo      IS NOT NULL THEN 1 ELSE 0 END
        + COALESCE(mepe_prim_vis, 0)   * CASE WHEN mepe_prim_vis   IS NOT NULL THEN 1 ELSE 0 END
        + COALESCE(mepe_reinc, 0)      * CASE WHEN mepe_reinc      IS NOT NULL THEN 1 ELSE 0 END
        + COALESCE(mepe_retrabalho, 0) * CASE WHEN mepe_retrabalho IS NOT NULL THEN 1 ELSE 0 END
        )
        /
        NULLIF(
            CASE WHEN mepe_ups        IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN mepe_prazo      IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN mepe_prim_vis   IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN mepe_reinc      IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN mepe_retrabalho IS NOT NULL THEN 1 ELSE 0 END
        , 0)
    , 2) as mepe,

    case
        when mepe >= 90 then 'A'
        when mepe >= 75 then 'B'
        when mepe >= 40 then 'C'
        when mepe < 40 then 'D'
    end classe_mepe 

    from classes
)

select * from mepe