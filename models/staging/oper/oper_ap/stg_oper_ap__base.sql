with source as (
select
    BASE_ID,
    CODIGO_PA,
    BAS_NOME,
    BAS_ENDERECO,
    BAS_AREA,
    BAS_QTD_OCO,
    BAS_UTMX,
    BAS_TMD,
    BAS_TE_FIXADO,
    BAS_UTMY,
    BAS_TMS,
    BAS_PRIORIDADE,
    BAS_STATUS,
    BAS_MANUTENCAO
  from {{ source('oper_ap','base') }}
)

select * from source