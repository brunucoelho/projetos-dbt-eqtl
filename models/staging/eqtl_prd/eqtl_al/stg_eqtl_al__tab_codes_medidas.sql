with source as (
    select
    "MANDANTE",
    "CATALOGO",
    "GRUPO_CODIGO",
    "CODIGO",
    "CODIGO_IDIOMA",
    "VERSAO",
    "VALIDO_DESDE",
    "TEXTO_BREVE_CODIGO",
    "DESC_CODIGO",
    "REGISTRO_INATIVO",
    "REGISTRO_ELIMINADO",
    "DATA_DADOS"
    from {{ source('eqtlinfo_prd_al','tab_codes_medidas') }}
)

select
*
from source