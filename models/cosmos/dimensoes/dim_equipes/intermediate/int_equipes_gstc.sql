{{ 
  config(
    materialized='view',
    tags=['dimension', 'equipes', 'intermediate', 'gstc']
  ) 
}}

-- =============================================================================
-- EQUIPES DO SISTEMA GSTC
-- =============================================================================
-- Processa dados de equipes do sistema GSTC (SGTSERVICOS)
-- Aplica normalização e busca dados de contratos e polos

WITH equipes_gstc_raw AS (
    SELECT 
        TUR.PRX_DESCRICAO AS prefixo,
        TUR.PRX_STATUS AS status_equipe,
        TTI.DESCRICAO AS tipo_equipe,
        CON.CTR_NUMERO AS contrato_sap,
        FO.FOR_NOME AS fornecedor_nome,
        CON.FOR_CODIGO AS fornecedor_codigo,
        CON.VIA_ID_PADRAO AS viatura_id
    FROM EQTLINFO_RAW.SGTSERVICOS.PREFIXO_TURMA AS TUR 
    INNER JOIN EQTLINFO_RAW.SGTSERVICOS.CONTRATO AS CON 
        ON TUR.PRX_CTR_ID = CON.CTR_ID 
    INNER JOIN EQTLINFO_RAW.SGTSERVICOS.TURMA_TIPO AS TTI 
        ON TTI.ID = TUR.PRX_TIPO_TURMA_ID 
    INNER JOIN EQTLINFO_RAW.SGTSERVICOS.FORNECEDOR AS FO 
        ON FO.FOR_CODIGO = CON.FOR_CODIGO
    WHERE TUR.PRX_DESCRICAO IS NOT NULL
      AND TRIM(TUR.PRX_DESCRICAO) != ''
      AND CON.CTR_NUMERO IS NOT NULL
),

-- Buscar polo do prefixo via tabela gstc_equipes
equipes_com_polo_gstc AS (
    SELECT 
        e.prefixo,
        e.status_equipe,
        e.tipo_equipe,
        e.contrato_sap,
        e.fornecedor_nome,
        g.polo,
        SPLIT_PART(g.distribuidora, '_', 2) AS empresa
    FROM equipes_gstc_raw e
    LEFT JOIN sb_performance.eqtl_corp.gp_gstc_equipes2021 g
        ON e.prefixo = g.prefixo
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY e.prefixo
        ORDER BY g.vigencia_final_eqp DESC NULLS LAST, g.vigencia_inicial_eqp DESC
    ) = 1
),

-- JOIN com dim_polos usando nome do polo (removendo acentos)
equipes_com_polo_id AS (
    SELECT 
        e.prefixo,
        e.status_equipe,
        e.tipo_equipe,
        e.contrato_sap,
        e.fornecedor_nome,
        e.polo,
        e.empresa,
        p.cod_polo as polo_id
    FROM equipes_com_polo_gstc e
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
),

-- JOIN com dim_contratos
equipes_com_contratos AS (
    SELECT 
        e.prefixo,
        e.status_equipe,
        e.tipo_equipe,
        e.polo,
        e.polo_id,
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
    'GSTC' as sistema_origem,
    COALESCE(status_equipe, 'Ativa') as status,
    tipo_equipe,
    CURRENT_TIMESTAMP as dt_ref
FROM equipes_com_contratos
WHERE prefixo IS NOT NULL
  AND polo IS NOT NULL
  AND contrato_sap IS NOT NULL
