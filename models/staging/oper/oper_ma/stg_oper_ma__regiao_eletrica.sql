with source as (
select
    REG_ELETRICA_ID,
    REL_DESCRICAO
  from {{ source('oper_ma','regiao_eletrica') }}
)

select * from source