with source as (
select
    REG_ELETRICA_ID,
    REL_DESCRICAO
  from {{ source('oper_ap','regiao_eletrica') }}
)

select * from source