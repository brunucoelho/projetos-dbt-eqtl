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
    NENHUM_MEDIDOR,
    INSTALA_MEDIDOR,
    MANTEM_MEDIDOR,
    RETIRA_MEDIDOR,
    TROCA_MEDIDOR,
    GERA_PENDENCIA
  from {{ source('oper_pi','code_medida') }}
)

select * from source