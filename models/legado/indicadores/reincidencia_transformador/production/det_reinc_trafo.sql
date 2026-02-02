{% set month_ref = get_month_ref() %}

SELECT 
EMPRESA,
REGIONAL,
SECCIONAL,
PRX_DESCRICAO EQUIPE,
DATA,
DATA_CONCLUSAO,
NATUREZA,
OCO_NUMERO,
NULL OCO_ID,
ABRANGENCIA,
PDF,
TIPO_EQP,
CHI,
CLIE,
REINCIDENTE_90_DIAS,
N_REINC,
DATA_CARGA DATA_DADOS
FROM {{ ref('vw_det_reinc_go') }}

UNION ALL

SELECT *
FROM {{ ref('vw_det_reinc_al') }}

UNION ALL

SELECT *
FROM {{ ref('vw_det_reinc_ap') }}

UNION ALL

SELECT *
FROM {{ ref('vw_det_reinc_ma') }}

UNION ALL

SELECT *
FROM {{ ref('vw_det_reinc_pa') }}

UNION ALL

SELECT *
FROM {{ ref('vw_det_reinc_pi') }}

UNION ALL

SELECT *
FROM {{ ref('vw_det_reinc_rs') }}

{% if is_incremental() %}
    -- Delete existing rows for the same month before inserting
    {% set delete_sql %}
        DELETE FROM {{ this }}
        WHERE TRUNC(DATA_CONCLUSAO,'MM') = TO_DATE({{ month_ref }}, 'YYYYMM')
    {% endset %}

    {% do run_query(delete_sql) %}
{% endif %}