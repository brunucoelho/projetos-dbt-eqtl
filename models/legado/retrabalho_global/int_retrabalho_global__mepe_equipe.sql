{{config(
    materialized='table'
)}}

with retrabalho as (
    select
    *,
    case
        when empresa = 'MARANHAO' then 'EQTL_MA'
        when empresa = 'PARA' then 'EQTL_PA'
        when empresa = 'ALAGOAS' then 'EQTL_AL'
        when empresa = 'PIAUI' then 'EQTL_PI'
        when empresa = 'GOIAS' then 'EQTL_GO'
        when empresa = 'RIO GRANDE DO SUL' then 'EQTL_RS'
        when empresa = 'AMAPA' then 'EQTL_AP'
    end as distribuidora
    from {{ ref('fct_retrabalho_global') }}
),

ups_base as (
    select
    *
    from {{ ref('int_ups__serv_exec_detalhado_global') }}
)

select 
ups.empresa,
ups.regional,
ups.ponto_apoio seccional,
ups.data_conclusao::date data,
ups.equipe,
ups.data_conclusao,
ups.os_oper nota,
ups.ostipo_id nota_tipo,
ups.sstipo_id nota_subtipo,
/*ups.ossubtipo_id nota_os_subtipo,
ups.grupo_code_medida nota_grupo_code,
ups.cod_conclusao nota_code,
ups.tipo_conclusao,
-- conclusao
-- causa
-- produtivo*/
case when retra.os_oper_origem is not null then true else false end as gerou_retrabalho,
retra.os_oper retrabalho_nota_seguinte,
retra.oco_data_conclusao retrabalho_dt_conclusao,
retra.prefixo retrabalho_equipe_conclusao

from ups_base ups
left join retrabalho retra
    on  ups.os_oper = retra.os_oper_origem
    and ups.empresa = retra.distribuidora
    and ups.ostipo_id = retra.ostipo_origem
    and ups.equipe = retra.prefixo_origem