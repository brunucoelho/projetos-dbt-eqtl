with source as (
select
    PREFIXO_TURMA_ID,
    BASE_ID,
    EMPREITEIRA_ID,
    PRX_DESCRICAO,
    PRX_STATUS,
    SYNC_PDA,
    PRX_FIMTURNO,
    TIPO_EQUIPE,
    LASTUPDATE,
    PARTICIPA_ESCALA,
    ZONA_PROCESSAMENTO,
    TB_EQUIPE_ID,
    PRX_NOME_INTERNO,
    DATA_DADOS
  from {{ source('oper_go','prefixo_turma') }}
)

select * from source