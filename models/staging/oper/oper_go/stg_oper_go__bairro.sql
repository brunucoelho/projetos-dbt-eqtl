with source as (
select
    "BAIRRO_ID",
    "BASE_ID",
    "LC_ID",
    "BAI_NOME",
    "BAI_NOME_RESUMIDO",
    "AREA_DESTINO_ID",
    "CONJUNTO_ID",
    "LASTUPDATE",
    "SYNC_PDA",
    "DATA_DADOS"
  from {{ source('oper_go','bairro') }}
)

select * from source