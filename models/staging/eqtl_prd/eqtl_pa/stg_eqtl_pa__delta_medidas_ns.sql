with source as (
    select
    "MANDANTE",
    "NOTA",
    "TIPO_NOTA",
    "MES_COMPETENCIA",
    "DATA_ENCERRAMENTO_NOTA",
    "MEDIDA",
    "GRUPO_MEDIDA",
    "CODIGO_MEDIDA",
    "CRIADO_POR",
    "DATA_CRIACAO_MEDIDA",
    "DATA_ALTERACAO_MEDIDA",
    "CONCLUIDO_POR",
    "DATA_CONCLUSAO_MEDIDA",
    "STATUS_MEDIDA",
    "TEXTO_MEDIDA",
    "INICIO_PROGRAMADO_MEDIDA",
    "FIM_PROGRAMADO_MEDIDA",
    "ALTERADO_POR",
    "OBJETO",
    "MNKAT",
    from {{ source('eqtlinfo_prd_pa','delta_medidas_ns') }}
)

select
*
from source