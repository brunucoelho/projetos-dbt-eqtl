with source as (
select
CODIGO_PA,
  REG_ELETRICA_ID,
  PAP_NOME,
  PAP_ENDERECO,
  PAP_TELEFONE,
  from {{ source('oper_ma','ponto_apoio') }}
)

select * from source