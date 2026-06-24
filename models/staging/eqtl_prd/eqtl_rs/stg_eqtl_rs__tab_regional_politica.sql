with source as (
    select
    MANDANTE,
    ESTRUTURA_REGIONAL_POLITICA,
    COD_REGIONAL,
    REGIONAL,
    COD_DISTRITAL,
    DISTRITAL,
    COD_SECCIONAL,
    SECCIONAL,
    COD_MUNICIPIO,
    MUNICIPIO,
    COD_LOCALIDADE,
    LOCALIDADE,
    SUPERINTENDENCIA,
    DATA_DADOS
    from {{ source('eqtlinfo_prd_rs','tab_regional_politica') }}
)

select
*
from source