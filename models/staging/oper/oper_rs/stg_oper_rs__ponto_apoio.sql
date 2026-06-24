with source as (
select
CODIGO_PA,
  REG_ELETRICA_ID,
  PAP_NOME,
  PAP_ENDERECO,
  PAP_TELEFONE,
  from {{ source('oper_rs','ponto_apoio') }}
)

select * from source