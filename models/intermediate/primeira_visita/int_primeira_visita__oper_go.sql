{{
    config(
        materialized="view"
    )
}}

with base as (
    select
        mvto.cd_movto_os_comercial,
        mvto.nr_os,
        mvto.ostipo_id,
        mvto.ossubtipo_id,
        subtipo.descricao_stpos,
        co.grupo_code_medida_id,
        con.cd_tp_conclusao_os,
        co.cdm_id,
        co.descricao,
        pt.prx_descricao,
        mvto.DT_SOLICITACAO,
        con.dt_conclusao,
        atr.atros_data,
        toc.HOST_VI_DT_INI_SERVICO,
        toc.HOST_VI_DT_FIM_SERVICO,
        toc.HOST_VI_DT_INI_DESLOCAMENTO,
        toc.HOST_VI_DT_FIM_DESLOCAMENTO,
        co.tipo_conclusao,
        mvto.cd_bairro
    from {{ ref('stg_oper_go__movto_os_comercial') }} mvto
    join {{ ref("stg_oper_go__conclui_os_comercial") }} con
        on con.cd_movto_os_comercial = mvto.cd_movto_os_comercial
    LEFT join {{ ref("stg_oper_go__code_medida") }} co
        on co.grupo_code_medida_id = mvto.grupo_code_medida_id
        and co.ossubtipo_id = mvto.ossubtipo_id
        and co.code_medida_id = con.cd_tp_conclusao_os
    left join {{ ref("stg_oper_go__turma_os_comercial") }} toc
        on toc.hist_os_turma_id = con.hist_os_turma_id
    left join {{ ref('stg_oper_go__atribui_os_comercial') }} atr
        on atr.atribuicao_os_id = toc.atribuicao_os_id
    left join {{ ref("stg_oper_go__historico_turma_plantao") }} htp
        on htp.hist_turma_plantao_id = toc.turma_plantao_id
    left join {{ ref("stg_oper_go__prefixo_turma") }} pt
        on pt.prefixo_turma_id = htp.prefixo_turma_id
    left join {{ ref("stg_oper_go__subtipo_de_os") }} subtipo
        on subtipo.ossubtipo_id = mvto.ossubtipo_id
),

map_estrutura_regional as (
    select
    visita.*,
    ibge.cidade,
    ibge.seccional,
    ibge.regional,
    ibge.dist,
    ibge.cod_ibge,
    from base visita
    left join {{ ref('stg_oper_go__bairro') }} bairro
        on bairro.bairro_id = visita.cd_bairro
    left join {{ ref('stg_oper_go__localidade') }} localidade
        on bairro.lc_id = localidade.lc_id
    left join {{ ref('stg_oper_go__municipio') }} municipio
        on municipio.mnc_id = localidade.mnc_id
    left join {{ ref('oper_go_municipios_ibge') }} mapibge
        on mapibge.oper_id = municipio.mnc_id
    left join {{ ref('municipios_ibge') }} ibge
        on ibge.cod_ibge = mapibge.ibge
),

cancelamento_removido as (
    select
    *
    from map_estrutura_regional
    where 
        descricao not like '%CANCELA%'
        and descricao not like 'SOBRA%'
        and descricao not like 'CONTING%'
),

normalizar_prefixo as (
    select
    *,
    {{ normalize_prefix_model('prx_descricao',"'GO'") }} equipe
    from cancelamento_removido
),

improdutivo as (
    select
    visita.*,
    case
        when produtivo.cdm_id is not null then true
        when visita.tipo_conclusao in ('R','I') then false
        when visita.tipo_conclusao = 'N' then true
    end as produtiva
    from normalizar_prefixo visita
    left join {{ ref('oper_go_code_medida_impro_produtivo') }} produtivo
        on produtivo.cdm_id = visita.cdm_id
),

codigo_conclusao as (
    select
    *,
    ostipo_id||'_'||ossubtipo_id||'_'||grupo_code_medida_id||'_'||cd_tp_conclusao_os codigo_conclusao
    from improdutivo
),

normalizar_tipos as (
    select
    visita.*,
    glossario.grupo
    from codigo_conclusao visita
    left join {{ ref('oper_go_glossario_atividades') }} glossario
        on glossario. ostipo_id = visita.ostipo_id
),

schema_output as (
    select
        cd_movto_os_comercial oper_movto_os_comercial,
        HOST_VI_DT_FIM_SERVICO::date dt_atividade,
        equipe,
        nr_os nota,
        descricao_stpos oper_nota_descricao,
        dist visita_empresa,
        regional visita_regional,
        seccional visita_seccional,
        cod_ibge municipio_ibge,
        cidade visita_municipio,
        grupo nota_grupo_tipo,
        codigo_conclusao oper_codigo_conclusao,
        ostipo_id nota_tipo,
        ossubtipo_id code,
        grupo_code_medida_id code_medida,
        cd_tp_conclusao_os code_medida_id,
        descricao visita_conclusao,
        produtiva visita_produtiva,
        atros_data dh_atribuicao,
        HOST_VI_DT_INI_DESLOCAMENTO dh_inicio_deslocamento,
        HOST_VI_DT_FIM_DESLOCAMENTO dh_fim_deslocamento,
        HOST_VI_DT_INI_SERVICO dh_inicio_servico,
        HOST_VI_DT_FIM_SERVICO dh_fim_servico
    from normalizar_tipos
)

select * from schema_output