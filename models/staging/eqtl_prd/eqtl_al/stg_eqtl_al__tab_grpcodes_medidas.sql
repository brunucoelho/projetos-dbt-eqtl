with source as (
    select
    "MANDANTE",
    "CATALOGO",
    "GRUPO_CODIGO",
    "CODIGO_IDIOMA",
    "TEXTO_BREVE_GRUPO_CODIGO",
    "DATA_DADOS"
    from {{ source('eqtlinfo_prd_al','tab_grpcodes_medidas') }}
)

select
*
from source