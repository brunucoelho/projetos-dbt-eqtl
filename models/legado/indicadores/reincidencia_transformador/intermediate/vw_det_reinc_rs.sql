SELECT
	DISTINCT
'EQTL_RS' empresa,
	gdf.regional,
	gdf.seccional,
	gdf.equipe,
	CAST(gdf.data AS DATE) DATA,
	gdf.data_conclusao,
	gdf.natureza,
	TO_CHAR(gdf.oco_numero) oco_numero,
	'' oco_id,
	gdf.abrangencia,
	gdf.pdf,
	CASE
		WHEN gdf.tipo_eqp IN ('TRANSFORMADOR', 'VAZIO', 'TRAFO', 'ENTRADA  PARTICULAR', 'TRAFO CEMAR') THEN 'TRANSFORMADOR'
		ELSE 'FUSÍVEL'
	END
tipo_eqp,
	gdf.chi_cliente,
	gdf.cli_cliente,
	CASE
		WHEN gdf2.reincidente_90 IS NOT NULL THEN 'S'
		ELSE 'N'
	END
reincidente_90_dias,
	SUM(gdf2.reincidente_90) n_reinc,
	CURRENT_TIMESTAMP data_dados
FROM
	SB_OPERACAO.OPERACAO_RS.gestao_dec_fec_RS gdf
LEFT JOIN (
	SELECT
		pdf,
		DATA,
		1 reincidente_90
	FROM
		SB_OPERACAO.OPERACAO_RS.gestao_dec_fec_RS
	WHERE
		natureza NOT IN ('Programada')
		AND chi_cliente > 0
		AND causa <> '512 - PICK NO ALIMENTADOR') gdf2 ON
	(( gdf2.pdf = gdf.pdf)
		AND (gdf2.data < gdf.data)
			AND (gdf2.data >= DATEADD(DAY, -90, gdf.data)))
WHERE
	1 = 1
	AND gdf.chi_cliente > 0
	AND tipo_eqp IN ('TRANSFORMADOR', 'VAZIO', 'TRAFO', 'ENTRADA  PARTICULAR', 'TRAFO CEMAR')
	AND gdf.natureza NOT IN ('PROGRAMADA')
	AND gdf.causa <> '512 - PICK NO ALIMENTADOR'
	AND TRUNC(gdf.data,'MM') = TO_DATE({{ get_month_ref() }}, 'YYYYMM')	
GROUP BY
	gdf.data,
	gdf.regional,
	gdf.seccional,
	gdf.equipe,
	gdf.data_conclusao,
	gdf.natureza,
	gdf.oco_numero,
	gdf.abrangencia,
	gdf.pdf,
	CASE
		WHEN gdf.tipo_eqp IN ('TRANSFORMADOR', 'VAZIO', 'TRAFO', 'ENTRADA  PARTICULAR', 'TRAFO CEMAR') THEN 'TRANSFORMADOR'
		ELSE 'FUSÍVEL'
	END,
	gdf.chi_cliente,
	gdf.cli_cliente,
	CASE
		WHEN gdf2.reincidente_90 IS NOT NULL THEN 'S'
		ELSE 'N'
	END