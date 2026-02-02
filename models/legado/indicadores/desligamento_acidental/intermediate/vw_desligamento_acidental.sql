SELECT 
	CURRENT_TIMESTAMP DATA_ETL,
	3 COD_EMPRESA,
    'EQTL_MA' empresa,   
    CASE 
    	WHEN substr(equipe,0,3) IN ('AL_','AP_','PA_','PI_','MA_','RS_','GO_') THEN substr(equipe,4,100)
    	ELSE equipe
    END EQUIPE,
    DATA::DATE DATA,
    EXTRACT (YEAR FROM DATA) ANO,
    EXTRACT (MONTH FROM DATA) MES,
    ocorrencia_id,
    CAUSA,
    sub_causa,
    ABRANGENCIA
FROM 
    SB_OPERACAO.OPERACAO_MA.GESTAO_DEC_FEC_MA gdf
WHERE 
    gdf.causa = 'FALHA OPERACIONAL'
    AND gdf.sub_causa IN ('ERRO DE OPERAÇÃO', 'SERVIÇO MAL EXECUTADO')
    AND abrangencia NOT IN ('CR', 'NI')
    AND EQUIPE IS NOT NULL
    AND OCORRENCIA_ID IS NOT NULL
    AND DATA IS NOT NULL
    AND TO_VARCHAR(TRUNC(DATA,'MM'),'YYYYMM') = {{ get_month_ref() }}

UNION ALL

SELECT 
	CURRENT_TIMESTAMP DATA_ETL,
	4 COD_EMPRESA,
    'EQTL_PA' empresa,   
    CASE 
    	WHEN substr(equipe,0,3) IN ('AL_','AP_','PA_','PI_','MA_','RS_','GO_') THEN substr(equipe,4,100)
    	ELSE equipe
    END EQUIPE,
    DATA::DATE DATA,
    EXTRACT (YEAR FROM DATA) ANO,
    EXTRACT (MONTH FROM DATA) MES,
    ocorrencia_id,
    CAUSA,
    sub_causa,
    ABRANGENCIA
FROM 
    SB_OPERACAO.OPERACAO_PA.GESTAO_DEC_FEC_PA gdf
WHERE 
    gdf.causa = 'FALHA OPERACIONAL'
    AND gdf.sub_causa IN ('ERRO DE OPERAÇÃO', 'SERVIÇO MAL EXECUTADO')
    AND abrangencia NOT IN ('CR', 'NI')
    AND EQUIPE IS NOT NULL
    AND OCORRENCIA_ID IS NOT NULL
    AND DATA IS NOT NULL
    AND TO_VARCHAR(TRUNC(DATA,'MM'),'YYYYMM') = {{ get_month_ref() }}

UNION ALL

SELECT 
	CURRENT_TIMESTAMP DATA_ETL,
	5 COD_EMPRESA,
    'EQTL_PI' empresa,   
    CASE 
    	WHEN substr(equipe,0,3) IN ('AL_','AP_','PA_','PI_','MA_','RS_','GO_') THEN substr(equipe,4,100)
    	ELSE equipe
    END EQUIPE,
    DATA::DATE DATA,
    EXTRACT (YEAR FROM DATA) ANO,
    EXTRACT (MONTH FROM DATA) MES,
    ocorrencia_id,
    CAUSA,
    sub_causa,
    ABRANGENCIA
FROM 
    SB_OPERACAO.OPERACAO_PI.GESTAO_DEC_FEC_PI gdf
WHERE 
    gdf.causa = 'FALHA OPERACIONAL'
    AND gdf.sub_causa IN ('ERRO DE OPERAÇÃO', 'SERVIÇO MAL EXECUTADO')
    AND abrangencia NOT IN ('CR', 'NI')
    AND EQUIPE IS NOT NULL
    AND OCORRENCIA_ID IS NOT NULL
    AND DATA IS NOT NULL
    AND TO_VARCHAR(TRUNC(DATA,'MM'),'YYYYMM') = {{ get_month_ref() }}

UNION ALL
    
SELECT 
	CURRENT_TIMESTAMP DATA_ETL,
	1 COD_EMPRESA,
    'EQTL_AL' empresa,   
    CASE 
    	WHEN substr(equipe,0,3) IN ('AL_','AP_','PA_','PI_','MA_','RS_','GO_') THEN substr(equipe,4,100)
    	ELSE equipe
    END EQUIPE,
    DATA::DATE DATA,
    EXTRACT (YEAR FROM DATA) ANO,
    EXTRACT (MONTH FROM DATA) MES,
    ocorrencia_id,
    CAUSA,
    sub_causa,
    ABRANGENCIA
FROM 
    SB_OPERACAO.OPERACAO_AL.GESTAO_DEC_FEC_AL gdf
WHERE 
    gdf.causa = 'FALHA OPERACIONAL'
    AND gdf.sub_causa IN ('ERRO DE OPERAÇÃO', 'SERVIÇO MAL EXECUTADO')
    AND abrangencia NOT IN ('CR', 'NI')
    AND EQUIPE IS NOT NULL
    AND OCORRENCIA_ID IS NOT NULL
    AND DATA IS NOT NULL
    AND TO_VARCHAR(TRUNC(DATA,'MM'),'YYYYMM') = {{ get_month_ref() }}

UNION ALL    

SELECT 
	CURRENT_TIMESTAMP DATA_ETL,
	7 COD_EMPRESA,
    'EQTL_RS' empresa,   
    CASE 
    	WHEN substr(equipe,0,3) IN ('AL_','AP_','PA_','PI_','MA_','RS_','GO_') THEN substr(equipe,4,100)
    	ELSE equipe
    END EQUIPE,
    DATA::DATE DATA,
    EXTRACT (YEAR FROM DATA) ANO,
    EXTRACT (MONTH FROM DATA) MES,
    ocorrencia_id,
    CAUSA,
    sub_causa,
    ABRANGENCIA
FROM 
    SB_OPERACAO.OPERACAO_RS.GESTAO_DEC_FEC_RS gdf
WHERE 
    gdf.causa = 'FALHA OPERACIONAL'
    AND gdf.sub_causa IN ('ERRO DE OPERAÇÃO', 'SERVIÇO MAL EXECUTADO')
    AND abrangencia NOT IN ('CR', 'NI')
    AND EQUIPE IS NOT NULL
    AND OCORRENCIA_ID IS NOT NULL
    AND DATA IS NOT NULL
    AND TO_VARCHAR(TRUNC(DATA,'MM'),'YYYYMM') = {{ get_month_ref() }}

UNION ALL

SELECT 
    CURRENT_TIMESTAMP DATA_ETL,
    6 COD_EMPRESA,
    'EQTL_GO' EMPRESA,
    NVL(pt.PRX_NOME_INTERNO,PRX_DESCRICAO) EQUIPE,
    oco.OCO_DATA_NR DATA,
    oco.OCO_ANO,
    oco.OCO_MES,
    oco.OCORRENCIA_ID,
    tdc.TCA_DESCRICAO CAUSA,
    '' SUB_CAUSA,
    oco.tb_tp_abrangencia ABRANGENCIA
FROM 
    EQTLINFO_RAW.OPER_GO.OCORRENCIA oco
    INNER JOIN EQTLINFO_RAW.OPER_GO.MOTIVO_DA_RECLAMACAO mdr ON mdr.tb_mt_nr_id = oco.tb_mt_nr_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.TIPO_DE_CAUSA tdc ON tdc.TB_CAUSA_ID = oco.TB_CAUSA_ID 
    INNER JOIN EQTLINFO_RAW.OPER_GO.HISTORICO_OCORRENCIA_TURMA hot ON hot.OCORRENCIA_ID = oco.OCORRENCIA_ID
    INNER JOIN EQTLINFO_RAW.OPER_GO.HISTORICO_TURMA_PLANTAO htp ON htp.HIST_TURMA_PLANTAO_ID = hot.HIST_TURMA_PLANTAO_ID 
    INNER JOIN EQTLINFO_RAW.OPER_GO.PREFIXO_TURMA pt ON pt.PREFIXO_TURMA_ID = HTP.PREFIXO_TURMA_ID 
WHERE 
    oco.oco_status = 'F'
    AND oco.tb_causa_id IN (79, 314)
    AND TO_VARCHAR(TRUNC(oco.oco_data_nr,'MM'),'YYYYMM') = {{ get_month_ref() }}
    AND oco.tb_tp_abrangencia NOT IN ('CR', 'NI')

UNION ALL
    
SELECT 
	CURRENT_TIMESTAMP DATA_ETL,
	2 COD_EMPRESA,
    'EQTL_AP' empresa,   
    CASE 
    	WHEN substr(equipe,0,3) IN ('AL_','AP_','PA_','PI_','MA_','RS_','GO_') THEN substr(equipe,4,100)
    	WHEN substr(equipe,4,1) = '-' THEN 'AP-'||equipe
    	ELSE equipe
    END EQUIPE,
    DATA::DATE DATA,
    EXTRACT (YEAR FROM DATA) ANO,
    EXTRACT (MONTH FROM DATA) MES,
    ocorrencia_id,
    CAUSA,
    sub_causa,
    ABRANGENCIA
FROM 
    SB_OPERACAO.OPERACAO_AP.GESTAO_DEC_FEC_AP gdf
WHERE 
    gdf.causa = 'FALHA OPERACIONAL'
    AND gdf.sub_causa IN ('ERRO DE OPERAÇÃO', 'SERVIÇO MAL EXECUTADO')
    AND abrangencia NOT IN ('CR', 'NI')
    AND EQUIPE IS NOT NULL
    AND OCORRENCIA_ID IS NOT NULL
    AND DATA IS NOT NULL
    AND TO_VARCHAR(TRUNC(DATA,'MM'),'YYYYMM') = {{ get_month_ref() }}