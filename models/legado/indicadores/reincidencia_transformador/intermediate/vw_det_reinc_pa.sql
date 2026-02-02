SELECT	DISTINCT
'EQTL_PA' empresa,
	CASE
		WHEN oo.polo = 'ABAETETUBA' THEN 'NORDESTE'
		WHEN oo.polo = 'ALENQUER' THEN 'OESTE'
		WHEN oo.polo = 'ALTAMIRA' THEN 'CENTRO'
		WHEN oo.polo IN ('BELÉM - AUGUSTO MONTENEGRO', 'BELÉM - CENTRO') THEN 'NORTE'
		WHEN oo.polo = 'BELÉM - BR' THEN 'NORTE'
		WHEN oo.polo = 'BREVES' THEN 'NORTE'
		WHEN oo.polo IN ('CASTANHAL', 'CAPANEMA') THEN 'NORDESTE'
		WHEN oo.polo = 'ITAITUBA' THEN 'OESTE'
		WHEN oo.polo = 'MARABÁ' THEN 'SUL'
		WHEN oo.polo = 'MARAJÓ' THEN 'NORTE'
		WHEN oo.polo IN ('PARAGOMINAS' , 'TOMEAÇU') THEN 'NORDESTE'
		WHEN oo.polo = 'PARAUAPEBAS' THEN 'SUL'
		WHEN oo.polo IN ('REDENÇÃO' , 'XINGUARA') THEN 'SUL'
		WHEN oo.polo = 'SANTARÉM' THEN 'OESTE'
		WHEN oo.polo = 'TUCURUI' THEN 'SUL'
	END REGIONAL,
	CASE
		WHEN oo.polo IN ('CASTANHAL', 'CAPANEMA') THEN 'CASTANHAL'
		WHEN oo.polo IN ('PARAGOMINAS' , 'TOMEAÇU') THEN 'PARAGOMINAS'
		WHEN oo.polo IN ('MARABÁ') THEN 'MARABA'
		WHEN oo.polo IN ('SANTARÉM') THEN 'SANTAREM'
		WHEN oo.polo IN ('BELÉM - AUGUSTO MONTENEGRO', 'BELÉM - CENTRO') THEN 'BELEM'
		WHEN OO.POLO = 'BELÉM - BR' THEN 'BELÉM-BR'
		ELSE oo.polo
	END seccional,
	gdf.equipe,
	CAST(gdf.data AS DATE) DATA,
	gdf.data_conclusao,
	gdf.natureza,
	TO_CHAR(gdf.oco_numero) oco_numero,
	TO_CHAR(gdf.ocorrencia_id) oco_id,
	gdf.abrangencia,
	gdf.pdf,
	DECODE(gdf.tipo_eqp, 'CHAVE FUSÍVEL', 'FUSÍVEL', 'INSTALACÃO TRANSFORMADORA COMPANHIA', 'TRANSFORMADOR') tipo_eqp,
	gdf.chi_cliente CHI,
	gdf.cli_cliente CLI,
	CASE
		WHEN gdf2.reincidente_90 IS NOT NULL THEN 'S'
		ELSE 'N'
	END
reincidente_90_dias,
	SUM(gdf2.reincidente_90) n_reinc,
	CURRENT_TIMESTAMP data_dados
FROM
	SB_OPERACAO.OPERACAO_PA.gestao_dec_fec_pa gdf
LEFT JOIN (
	SELECT
		pdf,
		DATA,
		1 reincidente_90
	FROM
		SB_OPERACAO.OPERACAO_PA.gestao_dec_fec_pa
	WHERE
		natureza NOT IN ('PROGRAMADO', 'Z-PROGRAMADO')) gdf2 ON
	( ( gdf2.pdf = gdf.pdf )
		AND ( gdf2.data < gdf.data )
			AND ( gdf2.data >= DATEADD(DAY, -90, gdf.data) ) )
LEFT JOIN (
	SELECT
		DISTINCT t.nome_conjunto,
		t.regional,
		t.polo
	FROM
		EQTLINFO_RAW.OPER_PA.rel_conj_eletrico t
	WHERE
		t.cod_formacao = 5
		AND t.nome_conjunto <> 'SIGFI_PORTO_DE_MOZ') oo ON
	oo.nome_conjunto = gdf.conjunto
WHERE
	gdf.procedencia = 'P'
	AND tipo_eqp IN ('TRANSFORMADOR')
	AND gdf.natureza NOT IN ('PROGRAMADO', 'Z-PROGRAMADO')
	AND TRUNC(gdf.data,'MM') = TO_DATE({{ get_month_ref() }}, 'YYYYMM')
	-- AND GDF.PDF = '46582'
GROUP BY
	gdf.data,
	CASE
		WHEN oo.polo = 'ABAETETUBA' THEN 'NORDESTE'
		WHEN oo.polo = 'ALENQUER' THEN 'OESTE'
		WHEN oo.polo = 'ALTAMIRA' THEN 'CENTRO'
		WHEN oo.polo IN ('BELÉM - AUGUSTO MONTENEGRO', 'BELÉM - CENTRO') THEN 'NORTE'
		WHEN oo.polo = 'BELÉM - BR' THEN 'NORTE'
		WHEN oo.polo = 'BREVES' THEN 'NORTE'
		WHEN oo.polo IN ('CASTANHAL', 'CAPANEMA') THEN 'NORDESTE'
		WHEN oo.polo = 'ITAITUBA' THEN 'OESTE'
		WHEN oo.polo = 'MARABÁ' THEN 'SUL'
		WHEN oo.polo = 'MARAJÓ' THEN 'NORTE'
		WHEN oo.polo IN ('PARAGOMINAS' , 'TOMEAÇU') THEN 'NORDESTE'
		WHEN oo.polo = 'PARAUAPEBAS' THEN 'SUL'
		WHEN oo.polo IN ('REDENÇÃO' , 'XINGUARA') THEN 'SUL'
		WHEN oo.polo = 'SANTARÉM' THEN 'OESTE'
		WHEN oo.polo = 'TUCURUI' THEN 'SUL'
	END,
	CASE
		WHEN oo.polo IN ('CASTANHAL', 'CAPANEMA') THEN 'CASTANHAL'
		WHEN oo.polo IN ('PARAGOMINAS' , 'TOMEAÇU') THEN 'PARAGOMINAS'
		WHEN oo.polo IN ('MARABÁ') THEN 'MARABA'
		WHEN oo.polo IN ('SANTARÉM') THEN 'SANTAREM'
		WHEN oo.polo IN ('BELÉM - AUGUSTO MONTENEGRO', 'BELÉM - CENTRO') THEN 'BELEM'
		WHEN OO.POLO = 'BELÉM - BR' THEN 'BELÉM-BR'
		ELSE oo.polo
	END,
	gdf.equipe,
	gdf.data_conclusao,
	gdf.natureza,
	gdf.oco_numero,
	gdf.ocorrencia_id,
	gdf.abrangencia,
	gdf.pdf,
	DECODE(gdf.tipo_eqp, 'CHAVE FUSÍVEL', 'FUSÍVEL', 'INSTALACÃO TRANSFORMADORA COMPANHIA', 'TRANSFORMADOR'),
	gdf.chi_cliente,
	gdf.cli_cliente,
	CASE
		WHEN gdf2.reincidente_90 IS NOT NULL THEN 'S'
		ELSE 'N'
	END