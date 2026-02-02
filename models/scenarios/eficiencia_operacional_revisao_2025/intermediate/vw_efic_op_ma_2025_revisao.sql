/* =====================================================================================
   EQTL_MA - UPS detalhado 2025 revisão
   Ajuste performance:
   - Pré-calcula chaves (regex/num/competência) uma vez
   - Remove LEFT JOIN com OR (vira 3 blocos + UNION ALL)
   - Troca DISTINCT por QUALIFY (dedupe controlado)
===================================================================================== */

WITH
/* ---------------------------
   1) UPS base (pré-cálculos)
---------------------------- */
UPS_BASE AS (
  SELECT
    ups.empresa,
    ups.p_regional              AS regional_prx,
    ups.p_polo                  AS polo_prx,
    ups.p_processo              AS processo,
    ups.serv_campo,
    ups.p_fornecedor            AS fornecedor,
    ups.equipe,
    TO_VARCHAR(ups.os_oper)     AS os_oper,
    ups.os,
    ups.ostipo_id,
    ups.ossubtipo_id,
    ups.tipo_conclusao,
    ups.ch_ups,
    ups.ups                     AS valor_ups,
    ups.competencia,
    ups.data_conclusao,
    ups.dias,
    ups.turnos,
    ups.data_dados,

    /* chaves / flags para join com INC */
    TO_CHAR(ups.competencia) AS comp_yyyymm, -- se já vem YYYYMM, fica igual
    IFF(TO_VARCHAR(ups.os_oper) LIKE '%-%', 1, 0) AS has_hyphen,
    IFF(TO_VARCHAR(ups.os_oper) ILIKE 'INC%', 1, 0) AS is_inc,

    -- /* antes do hífen (5484-5-2025 -> 5484) */
    TRY_TO_NUMBER(REGEXP_SUBSTR(TO_VARCHAR(ups.os_oper), '^[^-]+')) AS os_first_block_num,

    -- /* primeiro bloco de dígitos (INC1495... -> 1495..., "12345" -> 12345) */
    TRY_TO_NUMBER(REGEXP_SUBSTR(TO_VARCHAR(ups.os_oper), '\\d+')) AS os_digits_num,

    -- /* chave numérica “compacta” (remove / e -) para join com PP */
    TRY_TO_NUMBER(
      REPLACE(
        TRANSLATE(TO_VARCHAR(ups.os_oper), '/-', '  '),
        ' ',
        ''
      )
    ) AS os_oper_num_compact

  FROM {{ ref('serv_exec_detalhado2_2025_revisao')}} ups
  WHERE 1=1
    AND ups.empresa = 'EQTL_MA'
    AND ups.ch_ups NOT IN ('SERVICO INVALIDO')
),

/* ---------------------------
   2) RET normalizado (chave OS + competência)
---------------------------- */
RET_NORM AS (
  SELECT
    ret.*,
    /* normaliza ret.os para “bater” com ups.os_oper */
    CASE
      WHEN ret.os IS NOT NULL
       AND ret.os LIKE '____-%/%'
       AND POSITION('/' IN ret.os) > 0
       AND POSITION('-' IN ret.os) > 0
      THEN
        SPLIT_PART(ret.os, '/', 2) || '-' ||
        SPLIT_PART(SPLIT_PART(ret.os, '-', 2), '/', 1) || '-' ||
        SPLIT_PART(ret.os, '-', 1)
      ELSE ret.os
    END AS os_oper_key,
    TO_CHAR(ret.oco_data_conclusao_origem, 'YYYYMM') AS comp_yyyymm
  FROM SB_PERFORMANCE.EQTL_MA.RETRABALHO ret
),

/* ---------------------------
   3) PP base (prazo SAP STC MA)
---------------------------- */
PP_BASE AS (
  SELECT *
  FROM {{ ref('prazo_sap_stc_ma')}}
  WHERE tipo_nota NOT IN ('NR', 'IS')
),

/* ---------------------------
   4) INC base (reincidência)
---------------------------- */
INC_BASE AS (
  SELECT
    inc.*,
    TO_CHAR(inc.data, 'YYYYMM') AS inc_yyyymm,
    TRY_TO_NUMBER(REGEXP_SUBSTR(TO_VARCHAR(inc.oco_numero), '\\d+')) AS oco_num_digits
  FROM {{ ref('det_reinc_trafo')}} inc
  WHERE inc.empresa = 'EQTL_MA'
),

/* =====================================================================================
   5) Join UPS + RET + PP (sem INC ainda) para não repetir custo em 3 blocos
===================================================================================== */
UPS_ENRIQUECIDA AS (
  SELECT
    u.*,
    r.os_oper_origem,
    r.prefixo_origem,
    r.tipo_origem,
    r.tipo_conclusao_origem,
    pp.codigo_medida,
    TO_VARCHAR(pp.status_prazo) AS status_prazo
  FROM UPS_BASE u
  LEFT JOIN RET_NORM r
    ON u.os_oper = r.os_oper_key
   AND r.comp_yyyymm = u.comp_yyyymm
  LEFT JOIN PP_BASE pp
    ON TRY_TO_NUMBER(pp.nota) = u.os_oper_num_compact
),

/* =====================================================================================
   6) INC join em 3 casos (sem OR)
===================================================================================== */

/* Caso 1: OS_OPER com hífen -> exige vínculo de competência */
J1 AS (
  SELECT
    ue.*,
    i.reincidente_90_dias,
    i.n_reinc
  FROM UPS_ENRIQUECIDA ue
  LEFT JOIN INC_BASE i
    ON i.empresa = ue.empresa
   AND i.inc_yyyymm = ue.comp_yyyymm
   AND i.oco_num_digits = ue.os_first_block_num
  WHERE ue.has_hyphen = 1
),

/* Caso 2: OS_OPER tipo INC... -> NÃO exige competência */
J2 AS (
  SELECT
    ue.*,
    i.reincidente_90_dias,
    i.n_reinc
  FROM UPS_ENRIQUECIDA ue
  LEFT JOIN INC_BASE i
    ON i.empresa = ue.empresa
   AND i.oco_num_digits = ue.os_digits_num
  WHERE ue.is_inc = 1
),

/* Caso 3: normal -> NÃO exige competência */
J3 AS (
  SELECT
    ue.*,
    i.reincidente_90_dias,
    i.n_reinc
  FROM UPS_ENRIQUECIDA ue
  LEFT JOIN INC_BASE i
    ON i.empresa = ue.empresa
   AND i.oco_num_digits = ue.os_digits_num
  WHERE ue.is_inc = 0
    AND ue.has_hyphen = 0
),

ALL_UPS AS (
  SELECT * FROM J1
  UNION ALL
  SELECT * FROM J2
  UNION ALL
  SELECT * FROM J3
),

/* =====================================================================================
   7) Calcula flags e deduplica
===================================================================================== */
FINAL_BASE AS (
  SELECT
    a.*,

    /* tipo produtivo/improdutivo */
    CASE
      WHEN a.ostipo_id <> 'IS' AND a.ch_ups IN (
        'CORTE IMPRODUTIVO',
        'SERVICO INVALIDO',
        'SERVICO IMPRODUTIVO',
        'MT IMPRODUTIVA',
        'EMERGENCIA IMPRODUTIVA',
        'RELIGACAO IMPRODUTIVA'
      ) THEN 'IMPRODUTIVO'
      ELSE 'PRODUTIVO'
    END AS tipo,

    /* flags */
    CASE WHEN a.os_oper_origem IS NOT NULL THEN 1 ELSE 0 END AS flag_ret,

    CASE WHEN a.status_prazo = 'ATENDIDO FORA DO PRAZO' THEN 1 ELSE 0 END AS flag_prazo,

    CASE
      WHEN a.ostipo_id <> 'IS' AND a.ch_ups IN (
        'CORTE IMPRODUTIVO',
        'SERVICO INVALIDO',
        'SERVICO IMPRODUTIVO',
        'MT IMPRODUTIVA',
        'EMERGENCIA IMPRODUTIVA',
        'RELIGACAO IMPRODUTIVA'
      ) THEN 1 ELSE 0
    END AS flag_improdutiva,

    CASE
      WHEN a.ostipo_id = 'NR'
       AND a.tipo_conclusao IN (
        'CASA FECHADA',
        'ENDERECO NAO LOCALIZADO',
        'NÃO LOCALIZADO',
        'INTERRUPCAO INDIVIDUAL POR DEFEITO INTERNO',
        'LIGACAO CORTADA',
        'CONSUMIDOR CORTADO',
        'DISJUNTOR DESLIGADO',
        'NORMAL',
        'DEFEITO INTERNO',
        'OUTROS ESPECIFICAR (IMPROCEDENTE)',
        'SERVICO PREVENTIVO NAO PROGRAMADO',
        'ENCONTRADO NORMAL'
       )
      THEN 1 ELSE 0
    END AS flag_improcedencia,

    CASE WHEN a.reincidente_90_dias = 'S' THEN 1 ELSE 0 END AS flag_reincidencia

  FROM ALL_UPS a

  /* Dedup “controlado” (substitui DISTINCT) */
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY empresa, os_oper, os, competencia
    ORDER BY
      /* prioriza linhas com match de reincidência */
      IFF(reincidente_90_dias IS NOT NULL, 1, 0) DESC
  ) = 1
)

SELECT
  f.* EXCLUDE (
    COMP_YYYYMM,
    HAS_HYPHEN,
    IS_INC,
    OS_FIRST_BLOCK_NUM,
    OS_DIGITS_NUM,
    OS_OPER_NUM_COMPACT,
	fornecedor,
	flag_prazo
  ),
  f.fornecedor AS fonecedor,
  to_number(f.flag_prazo) as flag_prazo,
  CASE
    WHEN (f.flag_ret + f.flag_prazo + f.flag_improdutiva + f.flag_improcedencia + f.flag_reincidencia) >= 1
      THEN 'INEF.'
    ELSE 'EFIC.'
  END AS flag_total,

  /* categoria principal (prioridade igual seu script) */
  CASE
    WHEN f.flag_reincidencia = 1 THEN 'REINCIDENCIA'
    WHEN f.flag_improcedencia = 1 THEN 'IMPROCEDENCIA'
    WHEN f.flag_ret = 1 THEN 'RETRABALHO'
    WHEN f.flag_prazo = 1 THEN 'PRAZO'
    WHEN f.flag_improdutiva = 1 THEN 'IMPRODUTIVIDADE_UPS'
    ELSE ''
  END AS categoria

FROM FINAL_BASE f
 