{{ 
  config(
    materialized='table',
    alias='dim_equipes',
    database='sb_performance',
    schema='silver',
    tags=['dimension', 'equipes', 'core']
  ) 
}}

-- =============================================================================
-- DIMENSÃO DE EQUIPES - MODELO PRINCIPAL
-- =============================================================================
-- Consolida dados de equipes de todos os sistemas em uma única dimensão
-- Estrutura modular permite fácil adição de novos sistemas

WITH todas_equipes AS (
    -- SISTEMA SIGA
    SELECT 
        CAST(prefixo AS VARCHAR(100)) as prefixo,
        CAST(polo AS VARCHAR(200)) as polo,
        CAST(polo_id AS INT) as polo_id,
        CAST(contrato_sap AS VARCHAR(100)) as contrato_sap,
        CAST(contrato_id AS VARCHAR(100)) as contrato_id,
        CAST(empresa AS VARCHAR(10)) as empresa,
        CAST(sistema_origem AS VARCHAR(20)) as sistema_origem,
        CAST(status AS VARCHAR(50)) as status,
        CAST(NULL AS VARCHAR(50)) as tipo_equipe,  -- SIGA não tem tipo_equipe
        dt_ref
    FROM {{ ref('int_equipes_siga') }}
    
    UNION ALL
    
    -- SISTEMA GO  
    SELECT 
        CAST(prefixo AS VARCHAR(100)) as prefixo,
        CAST(polo AS VARCHAR(200)) as polo,
        CAST(polo_id AS INT) as polo_id,
        CAST(contrato_sap AS VARCHAR(100)) as contrato_sap,
        CAST(contrato_id AS VARCHAR(100)) as contrato_id,
        CAST(empresa AS VARCHAR(10)) as empresa,
        CAST(sistema_origem AS VARCHAR(20)) as sistema_origem,
        CAST(status AS VARCHAR(50)) as status,
        CAST(tipo_equipe AS VARCHAR(50)) as tipo_equipe,
        dt_ref
    FROM {{ ref('int_equipes_go') }}
    
    UNION ALL
    
    -- SISTEMA GSTC
    SELECT 
        CAST(prefixo AS VARCHAR(100)) as prefixo,
        CAST(polo AS VARCHAR(200)) as polo,
        CAST(polo_id AS INT) as polo_id,
        CAST(contrato_sap AS VARCHAR(100)) as contrato_sap,
        CAST(contrato_id AS VARCHAR(100)) as contrato_id,
        CAST(empresa AS VARCHAR(10)) as empresa,
        CAST(sistema_origem AS VARCHAR(20)) as sistema_origem,
        CAST(status AS VARCHAR(50)) as status,
        CAST(tipo_equipe AS VARCHAR(50)) as tipo_equipe,
        dt_ref
    FROM {{ ref('int_equipes_gstc') }}
    
    -- Para adicionar novos sistemas, adicionar UNION ALL aqui
),

equipes_com_validacao AS (
    SELECT 
        prefixo,
        polo,
        polo_id,
        contrato_sap,
        contrato_id,
        empresa,
        sistema_origem,
        status,
        tipo_equipe,
        dt_ref,
        -- Validações de integridade (verifica se houve match nas dimensões)
        CASE 
            WHEN polo_id = -1 THEN 'POLO_NAO_ENCONTRADO'
            WHEN contrato_id = '-1' THEN 'CONTRATO_NAO_ENCONTRADO' 
            ELSE 'COMPLETO'
        END as nivel_completude
    FROM todas_equipes
    WHERE prefixo IS NOT NULL
      AND TRIM(prefixo) != ''
      AND polo IS NOT NULL
      AND contrato_sap IS NOT NULL
)

SELECT 
    CAST(prefixo AS VARCHAR(100)) as prefixo,
    CAST(polo AS VARCHAR(200)) as polo,
    CAST(polo_id AS INT) as polo_id,
    CAST(contrato_sap AS VARCHAR(100)) as contrato_sap,
    CAST(contrato_id AS VARCHAR(100)) as contrato_id,
    CAST(empresa AS VARCHAR(10)) as empresa,
    CAST(sistema_origem AS VARCHAR(20)) as sistema_origem,
    CAST(status AS VARCHAR(50)) as status,
    CAST(tipo_equipe AS VARCHAR(50)) as tipo_equipe,
    CAST(nivel_completude AS VARCHAR(50)) as nivel_completude,
    dt_ref
FROM equipes_com_validacao
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY prefixo, polo, contrato_sap, sistema_origem
    ORDER BY dt_ref DESC
) = 1
