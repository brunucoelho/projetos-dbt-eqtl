{{
  config(
    materialized='incremental',
    tags=['gold', 'final', 'mepe_comercial']
  )
}}

{% set month_ref = get_month_ref() %}

SELECT 
    -- =============================================
    -- CAMPOS PADRÃO (comum a todas as fatos)
    -- =============================================
    a.equipe AS equipe,
    TO_DATE(a.competencia, 'YYYYMM') AS data,
    NVL(e.polo_id, ax.polo_id) AS polo_id,
    a.polo_prx AS polo,
    f.contrato_id AS contrato_id,
    b.contrato_sap AS contrato,
    a.empresa AS empresa,
    a.regional_prx AS regional,
    ct.fornecedor_sap AS fornecedor,
    
    -- =============================================
    -- CAMPOS ESPECÍFICOS DA FATO
    -- =============================================
    a.competencia,
    a.mes_ano,
    a.realizado_mensal,
    a.meta_mensal,
    a.media_ups_mes,
    a.dias_uteis,
    a.aderencia_ups,
    a.classe_mepe_ups,
    a.mepe_final,
    a.classe_mepe_final

FROM eqtl_corp.resultado_mepe a
LEFT JOIN {{ ref('dim_equipes') }} b
    ON a.equipe = b.prefixo 
    AND SPLIT_PART(a.empresa, '_', 2) = b.empresa
LEFT JOIN {{ ref('dim_polos') }} c
    ON b.polo_id = c.cod_polo
LEFT JOIN {{ ref('dim_polos_cosmos') }} e
    ON c.polo = e.pol_nome
LEFT JOIN {{ ref('dim_regionais') }} d
    ON c.cod_regional = d.cod_regional
LEFT JOIN {{ ref('dim_contratos_cosmos') }} f
    ON b.contrato_sap = f.cod_sap
LEFT JOIN {{ ref('dim_contratos') }} ct
    ON b.contrato_sap = ct.contrato_sap
LEFT JOIN {{ ref('dim_polos_cosmos') }} ax
    ON UPPER(TRANSLATE(
        REPLACE(a.polo_prx, '_', ' '),
        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ',
        'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn'
    )) = ax.pol_nome

WHERE a.mepe_final IS NOT NULL
  AND TO_DATE(a.competencia, 'YYYYMM') = TO_DATE({{ month_ref }}, 'YYYYMM')

{% if is_incremental() %}
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_DATE(competencia, 'YYYYMM') = TO_DATE({{ month_ref }}, 'YYYYMM')
    {% endset %}
    {% do run_query(delete_sql) %}
{% endif %}