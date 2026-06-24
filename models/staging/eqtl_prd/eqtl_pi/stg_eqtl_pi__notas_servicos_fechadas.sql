with source as (
    select
        MANDANTE,
        INSTALACAO,
        ltrim(NOTA, '0') NOTA,
        TIPO_NOTA,
        TEXTO_BREVE,
        GRUPO_CODES,
        CODIFICACAO,
        TIPO_CATALOGO,
        MEDIDAS,
        MES_COMPETENCIA,
        DATA_NOTA,
        CRIADO_POR,
        DATA_CRIACAO,
        INICIO_AVARIA,
        FIM_AVARIA,
        DATA_ALTERACAO,
        DATA_ENCERRAMENTO,
        CATEGORIA_TARIFA,
        PARCEIRO_NEGOCIO,
        ltrim(CONTA_CONTRATO, '0') CONTA_CONTRATO,
        COD_ATIVIDADE_CRM,
        SOLICITACAO_CRM,
        ESTRUT_REGIONAL_POLITICA,
        AGRUP_ESTRUTURA_REGIONAL,
        AREA_ESTRUT_REGIONAL,
        CARTEIRA_CLIENTE,
        ALTERADO_POR,
        SISTEMA_DIRECIONADO,
        CENTRO_CENTRAB,
        CENTRO_TRABALHO,
        UNIDADE_LEITURA,
        ID_ROTA,
        TIPO_CORTE,
        FINANCIAMENTO_PADRAO,
        STATUS_CCS,
        STATUSNTF2,
        STATUSDT,
        INICIO_DESEJADO,
        FIM_DESEJADO,
        NOTA_VINCULADA,
        PRIOK,
        TIPO_CARGA
    from {{ source('eqtlinfo_prd_pi','notas_servicos_fechadas') }}
),

deduplication as (
    select
    distinct *
    from source
    where mandante = '404'
    qualify row_number() over (partition by nota order by data_encerramento desc) = 1
)

select
*
from deduplication