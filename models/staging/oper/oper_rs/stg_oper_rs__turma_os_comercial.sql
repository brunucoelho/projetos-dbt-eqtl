with source as (
    select
    HIST_OS_TURMA_ID,
    ATRIBUICAO_OS_ID,
    TURMA_PLANTAO_ID,
    HOST_VI_STATUS,
    HOST_VI_DT_INI_DESLOCAMENTO,
    HOST_VI_DT_FIM_DESLOCAMENTO,
    HOST_VI_DT_INI_SERVICO,
    HOST_VI_DT_FIM_SERVICO,
    HOST_VI_DT_RETIRADA,
    HOST_KM_INICIAL,
    HOST_KM_FINAL
    from {{ source('oper_rs','turma_os_comercial') }}
),

deduplicate as (
    select
    distinct *
    from source
)

select * from deduplicate