with source as (
select
    "MNC_ID",
    "MNC_NOME",
    "MNC_SIGLA_UF",
    "COV",
    "MNC_TELEFONE1",
    "MNC_TELEFONE2",
    "MNC_TELEFONE3",
    "BASE_ID",
    "CODIGO_UT",
    "LASTUPDATE",
    "SYNC_PDA",
    "DATA_DADOS"
  from {{ source('oper_go','municipio') }}
)

select * from source