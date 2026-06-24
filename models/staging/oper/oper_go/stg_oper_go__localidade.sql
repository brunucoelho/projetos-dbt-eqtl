with source as (
select
    "LC_ID",
    "MNC_ID",
    "LOC_NOME",
    "LASTUPDATE",
    "SYNC_PDA",
    "DATA_DADOS"
from {{ source('oper_go','localidade') }}
)

select * from source