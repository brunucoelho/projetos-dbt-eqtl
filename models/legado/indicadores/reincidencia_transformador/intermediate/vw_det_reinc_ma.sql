SELECT DISTINCT
'EQTL_MA' empresa,
gdf.regional,
gdf.seccional,
gdf.equipe,
CAST(gdf.data AS DATE) DATA,
gdf.data_conclusao,
gdf.natureza,
TO_CHAR(gdf.oco_numero) oco_numero,
TO_CHAR(gdf.ocorrencia_id) oco_id,
gdf.abrangencia,
gdf.pdf,
DECODE(gdf.tipo_eqp,'CH FUSÍVEL','FUSÍVEL','TRAFO CEMAR','TRANSFORMADOR') tipo_eqp,
gdf.chi_cliente chi,
gdf.cli_cliente cli,
CASE 
WHEN gdf2.reincidente_90 IS NOT NULL THEN 'S'
ELSE 'N'
END reincidente_90_dias,
SUM(gdf2.reincidente_90) n_reinc,
CURRENT_TIMESTAMP data_dados      
FROM  SB_OPERACAO.OPERACAO_MA.gestao_dec_fec_ma gdf
LEFT JOIN  (SELECT pdf, data,
            1 reincidente_90
            FROM SB_OPERACAO.OPERACAO_MA.gestao_dec_fec_ma
            WHERE natureza NOT IN ('PROGRAMADO','Z-PROGRAMADO')) gdf2 ON (( gdf2.pdf = gdf.pdf )
                                                                     AND (gdf2.data < gdf.data )
                                                                     AND (gdf2.data >= DATEADD(DAY, -90, gdf.data) ) )
           WHERE  gdf.procedencia = 'P'
              AND tipo_eqp IN ('TRANSFORMADOR')
              AND gdf.natureza NOT IN ('PROGRAMADO','Z-PROGRAMADO')
              AND TRUNC(gdf.data,'MM') = TO_DATE({{ get_month_ref() }}, 'YYYYMM')
GROUP BY
gdf.data,
gdf.regional,
gdf.seccional,
gdf.equipe,
gdf.data_conclusao,
gdf.natureza,
gdf.oco_numero,
gdf.ocorrencia_id,
gdf.abrangencia,
gdf.pdf,
DECODE(gdf.tipo_eqp,'CH FUSÍVEL','FUSÍVEL','TRAFO CEMAR','TRANSFORMADOR'),
gdf.chi_cliente,
gdf.cli_cliente,
CASE
WHEN gdf2.reincidente_90 IS NOT NULL THEN 'S'
ELSE 'N'  END