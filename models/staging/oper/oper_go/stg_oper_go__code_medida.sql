with source as (
select
    CDM_ID,
    CODE_MEDIDA_ID,
    DESCRICAO,
    TIPO_CONCLUSAO,
    GRUPO_CODE_MEDIDA_ID,
    OSSUBTIPO_ID,
    SYNC_PDA,
    LASTUPDATE,
    CELG,
    NENHUM_MEDIDOR,
    INSTALA_MEDIDOR,
    MANTEM_MEDIDOR,
    RETIRA_MEDIDOR,
    TROCA_MEDIDOR,
    TARIFA_BRANCA,
    CD_INTEGRACAO,
    EXIGE_FOTO
  from {{ source('oper_go','code_medida') }}
)

select * from source