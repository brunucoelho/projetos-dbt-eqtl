{{
    config(
        materialized="view"
    )
}}

with base as (
    select
        nb_id,
        DT_ACTIVITY,
        tx_eq_tiponota,
        tx_os,
        tx_state,
        tx_city,
        NB_EQ_CODIGOMUNICIPIO,
        tx_worktype,
        tx_resourceexternalid,
        tx_status,
        tx_eq_grupocodemedida,
        tx_eq_grupocode,
        tx_eq_tipoconclusao,
        tx_eq_tipoconclusaoexec,
        tx_eq_tipoconclusaonaoexec,
        tx_text_eq_tipodecausatext,
        tx_text_eq_subtipocausatext,
        tx_eq_contacontrato,
        dt_timeassignment,
        dt_deliverywinstart,
        dt_deliverywinend,
        dt_estimatedtimearrival,
        nb_travelingtime,
        nb_duration

    from {{ ref('stg_siga__tb_ofsc_activities_rt') }} atividade
),

filtrar_notas_comerciais as (
    select
        *
    from base nota
    join {{ ref("glossario_atividades_siga") }} glossario
        on glossario.rotulo = nota.tx_worktype
    where glossario.grupo in (
        '[CT] - Corte/Suspensão de Fornecimento',
        '[DS] - Desligamento',
        '[LN] - Ligação Nova',
        '[MM] - Mudança de Medidor de Local',
        '[M1] - Alteração de Modalidade Tarifária',
        '[DR] - Deslocamento de Ramal',
        '[RC] - Reclamação do Cliente',
        '[IS] - Inspeção Técnica',
        '[RL] - Religação',
        '[TR] - Troca de Padrão / Equipamento',
        '[MQ] - Medição de Qualidade',
        '[OC] - Orçamento de Conexão BT',
        'Grupo A'
    )
),

filtrar_finalizadas as (
    select
    *
    from filtrar_notas_comerciais
    where tx_status in ('notdone','completed')
),

normalizar_prefixo as (
    select
    * ,
    {{ normalize_prefix_model('tx_resourceexternalid','tx_state') }} equipe
    from filtrar_finalizadas
),

normalizar_codigo_conclusao as (
    select
    * ,
    coalesce(tx_eq_tipoconclusaoexec, tx_eq_tipoconclusaonaoexec) codigo_conclusao
    from normalizar_prefixo
),

improdutivo as (
    select

    nota.* ,
    case
        when produtivo.tx_ref is not null then TRUE
        else decode(
                    propriedade.tx_ref,
                    'EQ_TipoConclusaoNaoExecutada', FALSE,
                    'EQ_TipoConclusaoExecutada', TRUE
                    )
    end as produtiva,
    propriedade.tx_valor as conclusao

    from normalizar_codigo_conclusao nota
    left join {{ ref('tb_dm_propriedades') }} propriedade
        on propriedade.tx_chave = nota.codigo_conclusao
    left join {{ ref('tb_dm_propriedades_impro_produtivo') }} produtivo
        on produtivo.tx_chave = nota.codigo_conclusao
),

map_estrutura_regional as (
    select
    nota.*,
    {{ validate_ibge_municipio('municipio.cod_ibge', uf='uf') }} municipio_ibge,
    municipio.dist,
    municipio.REGIONAL,
    municipio.SECCIONAL,
    municipio.cidade
    from improdutivo nota
    inner join {{ ref('municipios_ibge') }} municipio
        on {{ validate_ibge_municipio('municipio.cod_ibge', uf='uf') }}
            = {{ validate_ibge_municipio('nota.NB_EQ_CODIGOMUNICIPIO', uf='tx_state') }}
),

extrair_code_medida_id as (
    select
    *,
    regexp_substr(codigo_conclusao, '(\\d+)$', 1, 1, 'e', 1) code_medida_id
    from map_estrutura_regional
),

tempos_movimentos as (
    select
    * ,

    dateadd('minute',-180,dt_timeassignment) dh_atribuicao,
    dateadd('minute',-nb_travelingtime-180,dt_estimatedtimearrival) dh_inicio_deslocamento,
    dateadd('minute',-180,dt_estimatedtimearrival) dh_fim_deslocamento,
    dateadd('minute',-180,dt_estimatedtimearrival) dh_inicio_servico,
    dateadd('minute',nb_duration-180,dt_estimatedtimearrival) dh_fim_servico

    from extrair_code_medida_id
),

filtrar_notas_indesejas as (
    select
    *
    from tempos_movimentos
    where conclusao not in ('BAIXA POR RAJADA/ARRECADAÇÃO','SOBRAS','REJEICAO PARA CANCELAMENTO','REJEIÇÃO PARA CANCELAMENTO')
),

schema_output as (
    select 
    nb_id siga_nb_id,
    DT_ACTIVITY dt_atividade,
    equipe,
    tx_os nota,
    NOME_DO_TIPO_DE_ATIVIDADE siga_nota_descricao,
    dist visita_empresa,
    regional visita_regional,
    seccional visita_seccional,
    municipio_ibge,
    cidade visita_municipio,
    grupo nota_grupo_tipo,
    codigo_conclusao siga_codigo_conclusao,
    tx_eq_tiponota nota_tipo,
    tx_eq_grupocode code,
    tx_eq_grupocodemedida code_medida,
    code_medida_id,
    conclusao visita_conclusao,
    produtiva visita_produtiva,
    dh_atribuicao,
    dh_inicio_deslocamento,
    dh_fim_deslocamento,
    dh_inicio_servico,
    dh_fim_servico
    from filtrar_notas_indesejas
)

select *
from schema_output