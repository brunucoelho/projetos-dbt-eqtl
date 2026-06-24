with source as (
select
    OSTIPO_ID,
    DESCRICAO_TPOS,
    SIGLA_TPOS,
    TMEXECUCAO_TPOS,
    ATIVO,
    OSTIPO_ID_EXIBICAO
  from {{ source('oper_go','tipo_de_os') }}
)

select * from source