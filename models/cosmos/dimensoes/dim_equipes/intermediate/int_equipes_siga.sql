{{ 
  config(
    materialized='view',
    tags=['dimension', 'equipes', 'intermediate', 'siga']
  ) 
}}

-- =============================================================================
-- EQUIPES DO SISTEMA SIGA
-- =============================================================================
-- Processa dados de equipes do sistema SIGA com base na consulta fornecida
-- Aplica lógica de prefixos, polos e contratos do SIGA

WITH prefixos AS (
    SELECT
        DISTINCT
        REGEXP_REPLACE(tx_externalid, '_.*$', '') as empresa,
        REGEXP_REPLACE(tx_externalid, '^[A-Z]{2}_', '') as prefixo
    FROM eqtlinfo_raw.siga.tb_ofsc_resources_rt 
    WHERE 
        (LOWER(TRIM(tx_type)) = 'prefixo' 
         OR LOWER(TRIM(tx_type)) = 'prefixomanutencao')
        AND tx_externalid IS NOT NULL
),

polos AS (
    SELECT
        REGEXP_REPLACE(prefixo, '^[A-Z]{2}_', '') as prefixo,
        polo,
        REGEXP_REPLACE(distribuidora, '^[^_]*_', '') as empresa,
        vigencia_final_eqp,
        vigencia_inicial_eqp
    FROM eqtl_corp.gp_gstc_equipes2021
    WHERE REGEXP_REPLACE(distribuidora, '^[^_]*_', '') IN (
        'AL',
        'AP', 
        'MA',
        'PA',
        'PI',
        'RS'
    )
    QUALIFY
        ROW_NUMBER() OVER (
          PARTITION BY prefixo
          ORDER BY vigencia_final_eqp DESC NULLS LAST, vigencia_inicial_eqp DESC
        ) = 1
),

contratos AS (
    SELECT 
        prefixo,
        contrato,
        CASE 
            WHEN cod_empresa = 1 THEN 'AL'
            WHEN cod_empresa = 2 THEN 'AP'
            WHEN cod_empresa = 3 THEN 'MA'
            WHEN cod_empresa = 4 THEN 'PA'
            WHEN cod_empresa = 5 THEN 'PI'
            WHEN cod_empresa = 7 THEN 'RS'
        END as empresa
    FROM eqtl_corp.slv_equipe_contrato
    WHERE cod_empresa IN (1,2,3,4,5,7) 
      AND contrato IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
          PARTITION BY prefixo, cod_empresa
          ORDER BY ano, mes DESC
        ) = 1
),

equipes_siga_raw AS (
    SELECT
        a.prefixo,
        b.polo,
        COALESCE(a.empresa, b.empresa) as empresa,
        c.contrato as contrato_sap
    FROM prefixos a
    LEFT JOIN polos b
        ON a.prefixo = b.prefixo AND a.empresa = b.empresa
    LEFT JOIN contratos c
        ON a.prefixo = c.prefixo AND a.empresa = c.empresa
    WHERE a.prefixo IS NOT NULL
      AND TRIM(a.prefixo) != ''
),

-- JOIN com dim_polos usando nome do polo (removendo acentos)
equipes_com_polo AS (
    SELECT 
        e.prefixo,
        e.polo,
        e.empresa,
        e.contrato_sap,
        p.cod_polo as polo_id
    FROM equipes_siga_raw e
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

-- JOIN com dim_empresas usando sigla
equipes_com_empresa AS (
    SELECT 
        e.prefixo,
        e.polo,
        e.polo_id,
        e.empresa,
        e.contrato_sap,
        emp.cod_empresa
    FROM equipes_com_polo e
    LEFT JOIN {{ ref('dim_empresas') }} emp
        ON CONCAT('EQTL_', e.empresa) = emp.sigla_empresa
),

-- JOIN com dim_contratos
equipes_com_contratos AS (
    SELECT 
        e.prefixo,
        e.polo,
        e.polo_id,
        e.cod_empresa,
        e.contrato_sap,
        e.empresa,
        c.contrato_sap as contrato_id
    FROM equipes_com_empresa e
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
    'SIGA' as sistema_origem,
    'Ativa' as status,  -- Status padrão para SIGA
    CURRENT_TIMESTAMP as dt_ref
FROM equipes_com_contratos
WHERE prefixo IS NOT NULL
  AND polo IS NOT NULL
  AND contrato_sap IS NOT NULL
