SELECT
	DISTINCT
'EQTL_AP' empresa,
	REPLACE(gdf.regional, 'Á', 'A') regional,
	gdf.seccional,
	REPLACE(gdf.equipe, 'AP_AP-', '') equipe,
	CAST(gdf.data AS DATE) DATA,
	CAST(gdf.data_conclusao AS DATE) DATA_CONCLUSAO,
	gdf.natureza,
	TO_CHAR(gdf.oco_numero) oco_numero,
	TO_CHAR(gdf.ocorrencia_id) oco_id,
	gdf.abrangencia,
	gdf.pdf,
	CASE
		WHEN gdf.tipo_eqp IN ('TRANSFORMADOR') THEN 'TRANSFORMADOR'
		ELSE 'FUSÍVEL'
	END tipo_eqp,
	gdf.chi_cliente chi,
	gdf.cli_cliente clie,
	CASE
		WHEN gdf2.reincidente_90 IS NOT NULL THEN 'S'
		ELSE 'N'
	END reincidente_90_dias,
	SUM(gdf2.reincidente_90) n_reinc,
	CURRENT_TIMESTAMP data_dados
FROM
	SB_OPERACAO.OPERACAO_AP.gestao_dec_fec_AP gdf
LEFT JOIN (
	SELECT
		pdf,
		DATA,
		1 reincidente_90
	FROM
		SB_OPERACAO.OPERACAO_AP.gestao_dec_fec_AP
	WHERE
		natureza NOT IN ('PROGRAMADA')
		AND dec_cliente > 0
		AND causa <> 'IMPROCEDENTES') gdf2 ON
	( ( gdf2.pdf = gdf.pdf )
		AND ( gdf2.data < gdf.data )
			AND ( gdf2.data >= DATEADD(DAY, -90, gdf.data)))
WHERE
	1 = 1
	AND gdf.dec_cliente > 0
	AND tipo_eqp IN ('TRANSFORMADOR')
	AND gdf.natureza NOT IN ('PROGRAMADA')
	AND TO_CHAR(gdf.data, 'YYYY') IN (2023, 2024, 2025)
	AND gdf.causa <> 'IMPROCEDENTES'
	AND TRUNC(gdf.data,'MM') = TO_DATE({{ get_month_ref() }}, 'YYYYMM')	
GROUP BY
	gdf.data,
	REPLACE(gdf.regional, 'Á', 'A'),
	gdf.seccional,
	REPLACE(gdf.equipe, 'AP_AP-', ''),
	gdf.data_conclusao,
	gdf.natureza,
	gdf.oco_numero,
	gdf.ocorrencia_id,
	gdf.abrangencia,
	gdf.pdf,
	CASE
		WHEN gdf.tipo_eqp IN ('TRANSFORMADOR') THEN 'TRANSFORMADOR'
		ELSE 'FUSÍVEL'
	END,
	gdf.chi_cliente,
	gdf.cli_cliente,
	CASE
		WHEN gdf2.reincidente_90 IS NOT NULL THEN 'S'
		ELSE 'N'
	END
