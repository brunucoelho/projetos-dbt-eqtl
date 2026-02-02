{{
    config(
        materialized='view',
        schema='silver',
        tags=['aderencia_execucao', 'intermediate']
    )
}}

WITH agrupador AS (
  SELECT  avs.id idvalor, avs.NOME VALOR, as2.NOME CHAVE
  FROM EQTLINFO_RAW.SIPROG.AGRUPADOR_VALOR avs
  LEFT JOIN EQTLINFO_RAW.SIPROG.AGRUPADOR as2 ON avs.AGRUPADOR = as2.ID
)
SELECT 
    progsi.id AS ID_PROG,
    CASE 
      WHEN progsi.capex_opex = 1 THEN 'CAPEX'
      WHEN progsi.capex_opex = 2 THEN 'OPEX'
      ELSE 'DESCONHECIDO'
    END AS capex_opex,
    progsi.OBSERVACAO,
    ag.valor CAUSA_REPROGRAMACAO2,
    progsi.DATA_PROGRAMACAO_EXECUCAO,
    progsi.DATA_CRIACAO,
    progsi.DATA_ALTERACAO,
    CAST(progsi.ORCAMENTO_MAT AS VARCHAR) AS ORCAMENTO_MAT,
    CAST(progsi.ORCAMENTO_MO AS VARCHAR) AS ORCAMENTO_MO,
    CASE WHEN ag8.valor = 'CENTRO' AND ag8.chave = 'EQTL - PI' THEN 'PICOS'
        WHEN ag8.valor = 'SUL' AND ag8.chave = 'EQTL - PI' THEN 'FLORIANO' ELSE ag8.valor END AS regional_nome,
	ag8.chave empresa,
	es.CONTRATO,
    CAST(progsi.ORCAMENTO_TOTAL AS VARCHAR) AS ORCAMENTO_TOTAL,
    progsi.PRAZO_CONCLUSAO,
    ag2.valor PROGRAMACAO_EXECUTADA2,
    progsi.REGIONAL,
    ag3.valor RESTRICAO2,
    progsi.SEMANA_PROGRAMADA,
    ag4.valor SITUACAO_EXECUCAO2,
    ag5.valor STATUS_PROGRAMACAO2, 
    ag6.valor TIPO_INTERVENCAO2,
    ag7.valor TIPO_SERVICO_OBRA2,
    progsi.EQUIPE_PROGRAMADA AS idEquipe,
    ep.NOME nome_equipe,
    progsi.NOTA_PROJETO,
    progsi.NOTA_CLIENTE,
    progsi.ORIGEM_REPROGRAMACAO,
    progsi.NUMERO_SI,
    progsi.DESCRICAO_PI,
    progsi.BAIRRO,
    ag10.valor AS STATUS_SAP,
    ag11.valor AS OBRA_VALIDADA_CAMPO,
    ag14.valor AS OBRA_CONCLUIDA,
    ag12.valor AS CLASSE,
    ag13.valor AS ORIGEM_RECLAMACAO,
    progsi.JUSTIFICATIVA_REPROGRAMACAO,
    progsi.NOME_OBRA_MANUTENCAO,
    progsi.NUMERO_OCORRENCIA,
    progsi.PEP,
    ag9.valor AS PRIORIDADE,
    progsi.DATA_INSPECAO,
    current_timestamp as DATA_DADOS
  FROM EQTLINFO_RAW.SIPROG.PROGRAMACAO progsi
LEFT JOIN EQTLINFO_RAW.SIPROG.equipe ep ON ep.id = progsi.equipe_programada
LEFT JOIN EQTLINFO_RAW.SIPROG.empreiteira es ON es.id = ep.empreiteira
LEFT JOIN agrupador ag ON ag.idvalor = progsi.CAUSA_REPROGRAMACAO 
LEFT JOIN agrupador ag2 ON ag2.idvalor = progsi.PROGRAMACAO_EXECUTADA
LEFT JOIN agrupador ag3 ON ag3.idvalor = progsi.RESTRICAO
LEFT JOIN agrupador ag4 ON ag4.idvalor = progsi.SITUACAO_EXECUCAO 
LEFT JOIN agrupador ag5 ON ag5.idvalor = progsi.STATUS_PROGRAMACAO 
LEFT JOIN agrupador ag6 ON ag6.idvalor = progsi.TIPO_INTERVENCAO
LEFT JOIN agrupador ag7 ON ag7.idvalor = progsi.TIPO_SERVICO_OBRA
LEFT JOIN agrupador ag8 ON ag8.idvalor = progsi.REGIONAL 
LEFT JOIN agrupador ag9 ON ag9.idvalor = PROGSI.PRIORIDADE 
LEFT JOIN agrupador ag10 ON ag10.idvalor = progsi.SITUACAO_SAP 
LEFT JOIN agrupador ag11 ON ag11.idvalor = progsi.VALIDACAO_EM_CAMPO
LEFT JOIN agrupador ag12 ON ag12.idvalor = progsi.CLASSE 
LEFT JOIN agrupador ag13 ON ag13.idvalor = progsi.ORIGEM_RECLAMACAO
LEFT JOIN agrupador ag14 ON ag14.idvalor = progsi.obra_FINALIZADA

