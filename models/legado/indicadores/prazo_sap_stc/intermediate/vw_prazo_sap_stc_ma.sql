Select
	distinct
'EQTL_MA' EMPRESA,
	c.regional,
	c.distrital,
	CASE
		WHEN c.seccional = 'BURITICUPU' THEN 'ACAILANDIA'
		WHEN c.seccional = 'COROATA' THEN 'BACABAL'
		WHEN c.seccional = 'CODO' THEN 'CAXIAS'
		WHEN c.seccional IN ('AMARANTE DO MARANHAO', 'PORTO FRANCO') THEN 'IMPERATRIZ'
		WHEN c.seccional = 'MIRANDA DO NORTE' THEN 'ITAPECURU-MIRIM'
		WHEN c.seccional = 'LAGO DA PEDRA' THEN 'PEDREIRAS'
		WHEN c.seccional = 'CURURUPU' THEN 'PINHEIRO'
		WHEN c.seccional = 'BARRA DO CORDA' THEN 'PRESIDENTE DUTRA'
		WHEN c.seccional = 'ZE DOCA' THEN 'SANTA INES'
		WHEN c.seccional = 'COLINAS' THEN 'SAO JOAO DOS PATOS'
		WHEN c.seccional = 'COELHO NETO' THEN 'TIMON'
		ELSE c.seccional
	END BASE,
	c.seccional,
	c.municipio,
	c.localidade,
	n.area_estrut_regional,
	n.conta_contrato,
	n.instalacao,
	n.nota,
	vv.equipe_execucao,
	--a.nr_visita,
	n.tipo_nota,
	n.texto_breve,
	n.grupo_codes,
	n.codificacao,
	--a.equipe_execucao,
	--a.grupo_medida,
	--a.codigo_medida,
	aa.grupo_medida,
	aa.CODIGO_MEDIDA,
	aa.status_medida,
	CASE
		WHEN n.tipo_nota = 'MG' THEN DECODE(aa.Codigo_Medida, '0001', 'APROVADA C/NECESSIDADE DE INTERLIGAÇÃO', '0003', 'VISTORIA REPROVADA', '0002', 'VISTORIA APROVADA', 'EXEC', 'EM EXECUÇÃO')
		ELSE cd.descricao
	END DESCRICAO,
	'NA' MOTIVO,
	--a.local,
	to_char(aa.data_conclusao_medida, 'YYYYMM') mes_competencia,
	n.data_nota,
	n.data_criacao,
	aa.data_criacao_medida,
	--a.data_inicio_servico,
	--a.data_final_servico,
	n.inicio_desejado,
	n.fim_desejado,
	aa.fim_programado_medida,
	aa.data_conclusao_medida,
	CASE
		WHEN aa.fim_programado_medida IS NULL THEN 'SEM PRAZO'
		WHEN aa.data_conclusao_medida IS NULL THEN 'PENDENTE CONCLUSAO'
		WHEN (aa.fim_programado_medida<aa.data_conclusao_medida) THEN 'ATENDIDO FORA DO PRAZO'
		WHEN (aa.fim_programado_medida >= aa.data_conclusao_medida) THEN 'ATENDIDO NO PRAZO'
		ELSE ''
	END STATUS_PRAZO,
	n.status_ccs,
	n.financiamento_padrao,
	CURRENT_TIMESTAMP ATUALIZACAO
from
	eqtlinfo_prd.eqtl_ma.notas_servicos n
left join eqtlinfo_prd.eqtl_ma.medidas_notas_servicos aa on
	aa.nota = n.nota
left join eqtlinfo_prd.eqtl_ma.visitas_notas vv on
	vv.nota = n.nota
	and vv.data_final_servico = aa.data_conclusao_medida
left join eqtlinfo_prd.eqtl_ma.tab_regional_politica c on
	n.estrut_regional_politica = c.estrutura_regional_politica
left join eqtlinfo_raw.operacao_ma.code_medida cd on
	cd.code_medida_id = aa.codigo_medida
	and aa.grupo_medida = cd.grupo_code_medida_id
	and n.grupo_codes = cd.ossubtipo_id
	--left join   owengcmr.gp_gstc_equipes2021 e on e.chave = 'MARANHAO'||A.EQUIPE_EXECUCAO 
where
	n.tipo_nota IN ('MT', 'DS', 'LN', 'MG', 'RL', 'MM', 'TR', 'TP', 'RI', 'DR', 'IS', 'FP', 'MQ')
	and to_char(aa.data_conclusao_medida, 'YYYYMM') = {{ get_month_ref() }}
	and AA.GRUPO_MEDIDA not in ( 'AGDACEPV', 'CALCERD', 'ELIGACAO', 'ACEITSPA', 'AGCLSPAR', 'ANADIVIR', 'ATUALCAD', 'CONFCONF', 'CONFICAD',
'CONFTROC', 'DIRECION', 'DIRECIOO', 'DISPONPE', 'EFETFINA', 'ELABEOST', 'ELABORSV', 'ELESORCP', 'ELESORSP', 'ESTVBTEC', 'EXECTRPT',
'EXELIGPR', 'EXEOB120', 'EXOBRA60', 'FINAPADO', 'FUGADIVI', 'INFOREDE', 'ORÇAPTAV', 'REPRMEDI', 'SUSPOBRA', 'TRATACAN',
'TRATATDM', 'TRATCANC', 'TRATCTIN', 'TRATEXPA', 'TRATINRE', 'TRATREJE', 'TRPDEXPA', 'VALICADA', 'VERIDESL', 'VERILEIT', 'VERIPEGD',
'EMFATFIN', 'ANACAPAA', 'FINAPADR', 'ACEITECL', 'CADASTRO', 'ECOBRA60', 'ELABORÇA', 'EOBRA120', 'EOBRACRO', 'ESTUVTEC', 'EXECOBRA',
'LIBERARE', 'LIGATELE', 'RETOVIAB', 'VISLNEXP', 'ACEITECL', 'CADASTRO', 'ELABORÇA', 'ESTUVTEC', 'EXECOBRA', 'LIGATELE',
'AGUACLSP', 'ANAPROJJ', 'ATCADAST', 'ATUALGEO', 'COMCONCL', 'CONPENGD', 'COPENDEN', 'EXEOBR60', 'FLUXOCAR', 'GERAPARC', 'RECEPARC',
'REESTGGD', 'REESTUGD', 'REGNPRO', 'RORCERD', 'VALINIGD', 'AUTORELI', 'AGCLCPAR', 'EXOBR120', 'SUSSVIAB', 'EXOBRCRO', 'AGDCO120',
'AGCORCRG', 'UNIVERS', 'AGCORR60', 'INFCLIOB', 'CORRE120', 'ACEITCPA', 'EXECCRO', 'TRANSFAR', 'CORREC60', 'PAGCPART', 'GERABOCA',
'VISALTBR', 'VISALTCO')
	and n.grupo_codes not in ('DSBTREMO', 'DSDEFFAT', 'DSTEMPAT', 'LIGEMUC', 'LIGNOVRE', 'LNMICRGD', 'LNMINIGD')
	and n.codificacao not in ('CMRE', 'LNGA', 'PLPT', 'REDF')