{{
  config(
    materialized='incremental',
    tags=['gold', 'final', 'disponibilidade']
  )
}}

{% set month_ref = get_month_ref() %}

SELECT 
    -- =============================================
    -- CAMPOS PADRÃO (comum a todas as fatos)
    -- =============================================
    a.prefixo_padrao AS equipe,
    a.data,
    f.polo_id AS polo_id,
    d.polo AS polo,
    z.contrato_id AS contrato_id,
    c.contrato_sap AS contrato,
    d.empresa AS empresa,
    e.regional AS regional,
    ct.fornecedor_sap AS fornecedor,
    
    -- =============================================
    -- CAMPOS ESPECÍFICOS DA FATO
    -- =============================================
    a.escala_prevista,
    a.intervalo_previsto,
    a.jornada_prevista,
    a.turno_real,
    a.intervalo_real,
    a.tempo_disponivel,
    a.tempo_disponivel_excedente,
    a.tempo_indisponibilidade

FROM {{ ref('disponibilidade_operacional') }} a
LEFT JOIN {{ ref('dim_equipes') }} c 
    ON a.prefixo_padrao = c.prefixo 
    AND SPLIT_PART(a.origem, '_', 2) = c.empresa
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

WHERE TO_VARCHAR(a.data, 'YYYYMM') = {{ month_ref }}

{% if is_incremental() %}
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(data, 'YYYYMM') = {{ month_ref }}
    {% endset %}
    {% do run_query(delete_sql) %}
{% endif %}