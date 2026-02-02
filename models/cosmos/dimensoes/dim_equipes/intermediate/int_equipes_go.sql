{{ 
  config(
    materialized='view',
    tags=['dimension', 'equipes', 'intermediate', 'go']
  ) 
}}

-- =============================================================================
-- EQUIPES DO SISTEMA GO
-- =============================================================================
-- Processa dados de equipes do sistema GO com base na consulta fornecida
-- Aplica normalização de prefixos e busca último registro válido por equipe

WITH polos_gstc AS (
    -- Limpa prefixo 1x e usa SPLIT_PART p/ empresa (evita 2 regex por linha)
    WITH base AS (
        SELECT
            prefixo,
            polo,
            SPLIT_PART(distribuidora, '_', 2) AS empresa,
            vigencia_final_eqp,
            vigencia_inicial_eqp
        FROM sb_performance.eqtl_corp.gp_gstc_equipes2021
        WHERE SPLIT_PART(distribuidora, '_', 2) = 'GO'
    ),
    normalizado AS (
        SELECT
            CASE
              WHEN REGEXP_LIKE(prefixo, '^[A-Z]{3}.*$') THEN
                   'GO-' || SUBSTR(prefixo, 1, 3) || '-' || SUBSTR(prefixo, 4)
              ELSE prefixo
            END AS prefixo_fmt,
            polo,
            empresa,
            vigencia_final_eqp,
            vigencia_inicial_eqp
        FROM base
    )
    SELECT *
    FROM normalizado
    QUALIFY ROW_NUMBER() OVER (
              PARTITION BY prefixo_fmt
              ORDER BY vigencia_final_eqp DESC NULLS LAST, vigencia_inicial_eqp DESC
           ) = 1
),

htp AS (
    SELECT
        h.HTP_INICIO_TURNO,
        h.VIATURA_ID,
        COALESCE(pt.PRX_NOME_INTERNO, pt.PRX_DESCRICAO) AS PRX_DESCRICAO
    FROM EQTLINFO_RAW.OPER_GO.PREFIXO_TURMA pt
    LEFT JOIN EQTLINFO_RAW.OPER_GO.HISTORICO_TURMA_PLANTAO h
        ON pt.PREFIXO_TURMA_ID = h.PREFIXO_TURMA_ID
),

-- 1º: pega o último HTP_INICIO_TURNO por prefixo (barateia o sort)
ult_ts AS (
    SELECT
        PRX_DESCRICAO,
        MAX(HTP_INICIO_TURNO) AS max_inicio
    FROM htp
    GROUP BY PRX_DESCRICAO
),

-- 2º: volta pra linha "completa" e desempata por VIATURA_ID (se necessário)
ultimo_por_prefixo AS (
    SELECT
        h.HTP_INICIO_TURNO,
        h.VIATURA_ID,
        h.PRX_DESCRICAO
    FROM htp h
    JOIN ult_ts u
        ON u.PRX_DESCRICAO = h.PRX_DESCRICAO
       AND u.max_inicio     = h.HTP_INICIO_TURNO
    QUALIFY ROW_NUMBER() OVER (
              PARTITION BY h.PRX_DESCRICAO
              ORDER BY h.VIATURA_ID DESC
            ) = 1
),

equipes_go_raw AS (
    SELECT
        u.PRX_DESCRICAO                         AS prefixo,
        pv.VIA_CONTRATO_SAP                     AS contrato_sap,
        p.polo,
        p.prefixo_fmt,
        p.empresa
    FROM ultimo_por_prefixo u
    /* Cruza VIATURA do fato com ponte da operação GO */
    LEFT JOIN EQTLINFO_RAW.OPER_GO.VIATURA rv
        ON rv.VIATURA_ID = u.VIATURA_ID
    /* Busca contrato no PRD via VIA_CODIGO (garanta tipos iguais dos campos) */
    LEFT JOIN EQTLINFO_PRD.EQTL_GO.VIATURAS pv
        ON pv.VIA_CODIGO = u.VIATURA_ID
    /*+ BROADCAST(p) */ 
    LEFT JOIN polos_gstc p
        ON p.prefixo_fmt = u.PRX_DESCRICAO
),

-- Mapear polos para cod_polo usando JOIN com dim_polos (removendo acentos)
equipes_com_polo_id AS (
    SELECT 
        e.prefixo,
        e.contrato_sap,
        e.polo,
        p.cod_polo as polo_id,
        e.empresa
    FROM equipes_go_raw e
    LEFT JOIN {{ ref('dim_polos') }} p
        ON UPPER(TRIM(TRANSLATE(
            p.polo,
            'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ',
            'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn'
        ))) = UPPER(TRIM(TRANSLATE(
            e.polo,
            'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ',
            'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn'
        ))) AND e.empresa = split_part(p.sigla_empresa, '_', 2)
    WHERE e.prefixo IS NOT NULL
      AND TRIM(e.prefixo) != ''
),

equipes_com_contratos AS (
    SELECT 
        e.prefixo,
        e.polo_id,
        e.polo,
        e.contrato_sap,
        e.empresa,
        c.contrato_sap as contrato_id
    FROM equipes_com_polo_id e
    LEFT JOIN {{ ref('dim_contratos') }} c
        ON e.contrato_sap = c.contrato_sap and e.empresa = split_part(c.sigla_empresa, '_', 2)
)

SELECT 
    prefixo,
    polo,
    COALESCE(polo_id, -1) as polo_id,
    contrato_sap,
    COALESCE(contrato_id, '-1') as contrato_id,
    empresa,
    'GO' as sistema_origem,
    'Ativa' as status,  -- Status padrão para GO
    'Técnica' as tipo_equipe,  -- Tipo padrão para GO
    CURRENT_TIMESTAMP as dt_ref
FROM equipes_com_contratos
WHERE prefixo IS NOT NULL
  AND polo IS NOT NULL
  AND contrato_sap IS NOT NULL
