with source as (
select
    REG_ELETRICA_ID,
    REL_DESCRICAO,
    OBJECTID
  from {{ source('oper_al','regiao_eletrica') }}
)

select * from source