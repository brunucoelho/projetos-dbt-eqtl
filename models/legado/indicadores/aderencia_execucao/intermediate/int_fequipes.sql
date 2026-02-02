{{
    config(
        materialized='view',
        schema='silver',
        tags=['aderencia_execucao', 'intermediate']
    )
}}

WITH agrupador AS (
  SELECT ES.ID, ES.NOME EQUIPE, es2.NOME EMPREITEIRA, avs.NOME REGIONAL, as2.NOME EMPRESA
  FROM EQTLINFO_RAW.SIPROG.EQUIPE es
  LEFT JOIN EQTLINFO_RAW.SIPROG.EMPREITEIRA es2 ON es2.ID = es.EMPREITEIRA
  LEFT JOIN EQTLINFO_RAW.SIPROG.AGRUPADOR_VALOR avs ON avs.ID = es2.REGIONAL
  LEFT JOIN EQTLINFO_RAW.SIPROG.AGRUPADOR as2 ON avs.AGRUPADOR = as2.ID
)
SELECT
  eqp.id AS id_equipe,
  eqp.nome AS nome_equipe,
  cast(eqp.valor_referencia as varchar) as valor_referencia,
  es.id AS id_empreteira,
  es.nome AS nome_regional,
  es.contrato,
  avs.id AS id_agrupador,
  avs.descricao,
  avs.valor_pai,
  ag.EMPRESA,
  eqp.ativo
FROM EQTLINFO_RAW.SIPROG.equipe eqp
LEFT JOIN EQTLINFO_RAW.SIPROG.empreiteira es ON es.id = eqp.empreiteira
LEFT JOIN EQTLINFO_RAW.SIPROG.agrupador_valor avs ON eqp.tipo_equipe = avs.id
LEFT JOIN agrupador ag ON ag.id = es.id

