{{
  config(
    materialized='incremental',
    tags=['gold', 'final', 'religa']
  )
}}

{% set month_ref = get_month_ref() %}

SELECT 
    -- =============================================
    -- CAMPOS PADRÃO (comum a todas as fatos)
    -- =============================================
    a.equipe_conclusao AS equipe,
    a.dh_finalizado AS data,
    f.polo_id AS polo_id,
    COALESCE(d.polo, c.polo) AS polo,
    z.contrato_id AS contrato_id,
    COALESCE(c.contrato_sap, a.contrato) AS contrato,
    b.empresa AS empresa,
    e.regional AS regional,
    ct.fornecedor_sap AS fornecedor,
    
    -- =============================================
    -- CAMPOS ESPECÍFICOS DA FATO
    -- =============================================
    a.nota,
    a.conta_contrato,
    a.tipo,
    a.dh_abertura,
    a.dh_execucao_campo

FROM {{ ref('religa_vinculada') }} a
LEFT JOIN {{ ref('dim_empresas') }} b 
    ON a.sigla_empresa = b.sigla_empresa
LEFT JOIN {{ ref('dim_equipes') }} c 
    ON a.equipe_conclusao = c.prefixo
    AND SPLIT_PART(a.sigla_empresa, '_', 2) = c.empresa
LEFT JOIN {{ ref('dim_polos') }} d 
    ON c.polo_id = d.cod_polo
LEFT JOIN {{ ref('dim_polos_cosmos') }} f
    ON COALESCE(d.polo, c.polo) = f.pol_nome
LEFT JOIN {{ ref('dim_regionais') }} e 
    ON d.cod_regional = e.cod_regional
LEFT JOIN {{ ref('dim_contratos_cosmos') }} z
    ON COALESCE(c.contrato_sap, a.contrato) = z.cod_sap
LEFT JOIN {{ ref('dim_contratos') }} ct
    ON COALESCE(c.contrato_sap, a.contrato) = ct.contrato_sap

WHERE TO_VARCHAR(a.dh_finalizado, 'YYYYMM') = {{ month_ref }}

{% if is_incremental() %}
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(data, 'YYYYMM') = {{ month_ref }}
    {% endset %}
    {% do run_query(delete_sql) %}
{% endif %}