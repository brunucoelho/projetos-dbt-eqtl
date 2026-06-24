{{config(
    materialized='incremental',
    unique_key=['nota', 'medida', 'nr_visita']
)}}

with prazos as (
    select *
    from {{ ref("int_prazo_anexo_4__al") }}
    {% if is_incremental() %}
        where data_nota > (select max(data_nota) from {{ this }})
    {% endif %}
),

visitas as (
    select 
    LPAD(nota,12,0) nota,
    nr_visita,
    medida,
    data_inicio_deslocamento,
    data_final_deslocamento,
    data_inicio_servico,
    data_final_servico,
    {{ normalize_prefix_model('equipe_execucao',"'AL'") }} equipe_execucao,
    matricula_executor,
    nome_executor
    from {{ ref("stg_eqtl_al__visitas_notas") }}
)

select 
pra.*,
vst.* exclude(nota, medida)
from prazos pra
inner join visitas vst
    on vst.nota = pra.nota
    and vst.medida = pra.medida