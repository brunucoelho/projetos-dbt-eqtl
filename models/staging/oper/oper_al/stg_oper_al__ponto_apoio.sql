with source as (
select
    CODIGO_PA,
    REG_ELETRICA_ID,
    PAP_NOME,
    PAP_ENDERECO,
    PAP_TELEFONE,
    CONTRATO_ID,
  from {{ source('oper_al','ponto_apoio') }}
)

select * from source