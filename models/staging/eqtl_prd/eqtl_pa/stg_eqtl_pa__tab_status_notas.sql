with source as (
    select
    "STATUS_CCS",
    "CODIGO_BW",
    "CODIGO_CCS",
    "STATUS"
    from {{ source('eqtlinfo_prd_pa','tab_status_notas') }}
)

select
*
from source