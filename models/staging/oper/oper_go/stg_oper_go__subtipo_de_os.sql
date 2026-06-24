with source as (
select
    "OSTIPO_ID",
    "OSSUBTIPO_ID",
    "DESCRICAO_STPOS",
    "SYNC_PDA",
    "LASTUPDATE",
    "ATIVO",
    "EXIGE_VALIDACAO",
    "IND_ENVIAR_INTEGRACAO",
    "IND_ORDEM_JURIDICA",
    "IND_BLOQUEIO_FERIADO",
    "DEVOLVER_CANCELADA",
    "SERV_ESPECIALIZADO"
  from {{ source('oper_go','subtipo_de_os') }}
)

select * from source