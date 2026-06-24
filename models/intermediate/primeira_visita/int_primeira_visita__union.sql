with base as (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_primeira_visita__siga'),
            ref('int_primeira_visita__oper_go')
        ]
    ) }}
),

identificador as (
    select *,
    {{ dbt_utils.generate_surrogate_key(['siga_nb_id', 'oper_movto_os_comercial', 'visita_empresa']) }} as _dbt_unique_key
    from base
)

select * from identificador 