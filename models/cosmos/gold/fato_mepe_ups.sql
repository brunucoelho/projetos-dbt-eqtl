{{
  config(
    materialized='incremental',
    tags=['gold', 'final', 'mepe']
  )
}}

{% set month_ref = get_month_ref() %}

SELECT 
    -- =============================================
    -- CAMPOS PADRÃO (comum a todas as fatos)
    -- =============================================
    a.equipe AS equipe,
    TO_DATE(a.competencia, 'YYYYMM') AS data,
    f.polo_id AS polo_id,
    d.polo AS polo,
    z.contrato_id AS contrato_id,
    c.contrato_sap AS contrato,
    a.empresa AS empresa,
    e.regional AS regional,
    ct.fornecedor_sap AS fornecedor,
    
    -- =============================================
    -- CAMPOS ESPECÍFICOS DA FATO
    -- =============================================
    a.competencia,
    a.realizado_mensal,
    a.dias_uteis,
    a.meta_mensal,
    a.ader_meta_ups,
    a.classe_mepe_ups

FROM sb_performance.eqtl_corp.gp_mepe_ups a
LEFT JOIN {{ ref('dim_equipes') }} c 
    ON a.equipe = c.prefixo 
    AND SPLIT_PART(a.empresa, '_', 2) = c.empresa
LEFT JOIN {{ ref('dim_polos') }} d 
    ON c.polo_id = d.cod_polo
LEFT JOIN {{ ref('dim_polos_cosmos') }} f
    ON d.polo = f.pol_nome
LEFT JOIN {{ ref('dim_regionais') }} e 
    ON d.cod_regional = e.cod_regional
LEFT JOIN {{ ref('dim_contratos_cosmos') }} z
    ON c.contrato_sap = z.cod_sap
LEFT JOIN {{ ref('dim_contratos') }} ct
    ON c.contrato_sap = ct.contrato_sap

WHERE TO_DATE(a.competencia, 'YYYYMM') = TO_DATE({{ month_ref }}, 'YYYYMM')

{% if is_incremental() %}
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_DATE(competencia, 'YYYYMM') = TO_DATE({{ month_ref }}, 'YYYYMM')
    {% endset %}
    {% do run_query(delete_sql) %}
{% endif %}