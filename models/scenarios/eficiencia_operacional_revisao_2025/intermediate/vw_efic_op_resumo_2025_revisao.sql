Select
a.empresa,
a.regional_prx,
a.polo_prx,
a.tipo,
a.processo,
a.serv_campo,
a.equipe,
a.fonecedor,
a.competencia,
LPAD(a.competencia,4) ANO,
count(a.os_oper) QTD_OS,
a.ostipo_id,
a.flag_total,
a.categoria,
sum(a.valor_ups) QTD_UPS

FROM {{ ref('efic_oper_detalhado_2025_revisao') }} A

 
group by 
 
a.empresa,
a.regional_prx,
a.polo_prx,
a.tipo,
a.processo,
a.serv_campo,
a.equipe,
a.fonecedor,
a.competencia,
a.ostipo_id,
a.flag_total,
a.categoria