{{
  config(
    materialized='incremental',
    tags=['gold', 'final', 'corte']
  )
}}

{% set month_ref = get_month_ref() %}

SELECT 
    -- =============================================
    -- CAMPOS PADRÃO (comum a todas as fatos)
    -- =============================================
    a.equipe_conclusao AS equipe,
    a.dt_competencia AS data,
    NVL(f.polo_id, ax.polo_id) AS polo_id,
    NVL(a.polo, d.polo) AS polo,
    z.contrato_id AS contrato_id,
    a.contrato_conclusao AS contrato,
    a.empresa AS empresa,
    NVL(a.regional, e.regional) AS regional,
    ct.fornecedor_sap AS fornecedor,
    
    -- =============================================
    -- CAMPOS ESPECÍFICOS DA FATO
    -- =============================================
    a.nota,
    a.valor_divida,
    a.prioridade,
    a.modalidade_prioridade,
    a.contrato_atribuicao,
    a.dh_execucao_campo,
    a.historico_atribuicoes,
    a.qtd_atribuicoes

FROM {{ ref('corte_prioridade') }} a
LEFT JOIN {{ ref('dim_equipes') }} c 
    ON a.equipe_conclusao = c.prefixo 
    AND split_part(a.sigla_empresa, '_', 2) = c.empresa
LEFT JOIN {{ ref('dim_polos') }} d 
    ON c.polo_id = d.cod_polo
LEFT JOIN {{ ref('dim_polos_cosmos') }} f
    ON NVL(a.polo, d.polo) = f.pol_nome
LEFT JOIN {{ ref('dim_regionais') }} e 
    ON d.cod_regional = e.cod_regional
LEFT JOIN {{ ref('dim_contratos_cosmos') }} z
    ON a.contrato_conclusao = z.cod_sap
LEFT JOIN {{ ref('dim_contratos') }} ct
    ON a.contrato_conclusao = ct.contrato_sap
LEFT JOIN {{ ref('dim_polos_cosmos') }} ax
    ON UPPER(TRANSLATE(
        REPLACE(a.polo, '_', ' '),
        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ',
        'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn'
    )) = ax.pol_nome

WHERE TO_VARCHAR(a.dt_competencia, 'YYYYMM') = {{ month_ref }}

{% if is_incremental() %}
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TO_VARCHAR(data, 'YYYYMM') = {{ month_ref }}
    {% endset %}
    {% do run_query(delete_sql) %}
{% endif %}