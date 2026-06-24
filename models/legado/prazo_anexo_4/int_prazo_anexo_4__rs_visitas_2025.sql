select
'EQTL_RS' empresa,
{{ normalize_prefix_model('act.tx_resourceexternalid',"'RS'") }} equipe_execucao, 
trunc(periodo,'MM') competencia,
sum(case when tsc.prazo in ('NP') then 1 else 0 end) notas_dentro_prazo,
sum(case when tsc.prazo in ('FP') then 1 else 0 end) notas_fora_prazo,
sum(case when tsc.prazo in ('NP','FP') then 1 else 0 end) notas_total,
div0null(notas_dentro_prazo, notas_total) aderencia_prazo
from eqtlinfo_prd.gestinfo_rs.tab_serv_atend_prazo_etapa_01_indic_a4 tsc
left join eqtlinfo_raw.siga.tb_ofsc_activities_rt act
    on to_char(nota) = act.tx_os
    and act.tx_state = 'RS'
    and data_fim_servico::date = try_to_date(data_hora_acao_conclusao,'YYYY-MM-DD HH24:MI')
WHERE 0=0
AND tsc.NOME_ITEM = 'SERVIÇOS COMERCIAIS - ANEXO IV - ATENDIDOS NO PRAZO - CEEE-D EQTL ENERGIA'
and trunc(periodo,'MM') <= '2026-03-01'
group by all