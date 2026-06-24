with source as (
select
    REG_ELETRICA_ID,
    REL_DESCRICAO,
    OBJECTID
  from {{ source('oper_go','regiao_eletrica') }}
)

select * from source