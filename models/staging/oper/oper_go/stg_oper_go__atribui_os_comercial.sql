with source as (
select
    "ATRIBUICAO_OS_ID",
    "CD_MOVTO_OS_COMERCIAL",
    "PREFIXO_TURMA_ID",
    "ATROS_DATA",
    "ATROS_STATUS",
    "TURMA_PLANTAO_ID",
    "ATR_SEQUENCIA",
    "ATROS_PRIORIDADE",
    "ATROS_AGENDAMENTO",
    "DATA_DADOS"
  from {{ source('oper_go','atribui_os_comercial') }}
)

select * from source