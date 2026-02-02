{{
  config(
    materialized='incremental',
    tags=['gold', 'final', 'aderencia']
  )
}}

{% set month_ref = get_month_ref()  %}

SELECT 
    a.prefixo_padrao AS equipe,
    a.data,
    f.polo_id AS polo_id,
    d.polo AS polo,
    z.contrato_id AS contrato_id,
    eq.contrato_sap AS contrato,
    d.empresa AS empresa,
    e.regional AS regional,
    c.fornecedor_sap AS fornecedor,
    

    a.horario_inicio_escala AS dh_ini_escala,
    a.horario_fim_escala AS dh_fim_escala,
    a.htp_inicio_turno AS dh_ini_turno,
    a.htp_fim_turno AS dh_fim_turno,
    a.estado,
    a.atraso_minutos

FROM {{ ref('aderencia_escala') }} a
LEFT JOIN {{ ref('dim_equipes') }} eq
    ON eq.prefixo = a.prefixo_padrao 
    AND SPLIT_PART(a.origem, '_', 2) = eq.empresa
LEFT JOIN {{ ref('dim_polos') }} d 
    ON eq.polo_id = d.cod_polo
LEFT JOIN {{ ref('dim_polos_cosmos') }} f
    ON d.polo = f.pol_nome
LEFT JOIN {{ ref('dim_regionais') }} e 
    ON d.cod_regional = e.cod_regional
LEFT JOIN {{ ref('dim_contratos_cosmos') }} z
    ON eq.contrato_sap = z.cod_sap
LEFT JOIN {{ ref('dim_contratos') }} c
    ON eq.contrato_sap = c.contrato_sap

WHERE TO_VARCHAR(a.data, 'YYYYMM') = {{ month_ref }}

{% if is_incremental() %}
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(data, 'YYYYMM') = {{ month_ref }}
    {% endset %}
    {% do run_query(delete_sql) %}
{% endif %}