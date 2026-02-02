SELECT
	T.*,
	CASE
		WHEN (T.FLAG_RET + T.FLAG_PRAZO + T.FLAG_IMPRODUTIVA + T.FLAG_IMPROCEDENCIA + T.FLAG_REINCIDENCIA) >= 1 THEN 'INEF.'
		ELSE 'EFIC.'
	END AS FLAG_TOTAL,
	COALESCE(
        CASE WHEN T.FLAG_REINCIDENCIA = 1 THEN 'REINCIDENCIA' END,
        CASE WHEN T.FLAG_IMPROCEDENCIA = 1 THEN 'IMPROCEDENCIA' END,
        CASE WHEN T.FLAG_RET = 1 THEN 'RETRABALHO' END,
        CASE WHEN T.FLAG_PRAZO = 1 THEN 'PRAZO' END,
        CASE WHEN T.FLAG_IMPRODUTIVA = 1 THEN 'IMPRODUTIVIDADE_UPS' END,
        ''
    ) AS CATEGORIA
FROM
	(
	SELECT
		ups.empresa,
		ups.p_Regional AS regional_prx,
		ups.p_Polo AS polo_prx,
		ups.p_Processo AS processo,
		ups.serv_campo,
		ups.p_fornecedor AS fornecedor,
		ups.equipe,
		TO_CHAR(ups.os_oper) AS OS_OPER,
		ups.os,
		ups.ostipo_id,
		ups.ossubtipo_id,
		ups.tipo_conclusao,
		CASE
			WHEN UPS.Ch_Ups IN ('CORTE IMPRODUTIVO', 'SERVICO INVALIDO', 'SERVICO IMPRODUTIVO', 'MT IMPRODUTIVA', 'EMERGENCIA IMPRODUTIVA', 'RELIGACAO IMPRODUTIVA')THEN 'IMPRODUTIVO'
			ELSE 'PRODUTIVO'
		END AS tipo,
		ups.ch_ups,
		ups.UPS AS valor_ups,
		ups.competencia,
		ups.data_conclusao,
		UPS.DIAS,
		ups.turnos,
		RET.OS_OPER_ORIGEM,
		RET.PREFIXO_ORIGEM,
		RET.TIPO_ORIGEM,
		RET.TIPO_CONCLUSAO_ORIGEM,
		pp.codigo_medida,
		TO_CHAR(pp.status_prazo) AS STATUS_PRAZO,
		INC.REINCIDENTE_90_DIAS,
		INC.N_REINC,
		CASE
			WHEN RET.OS_OPER_ORIGEM IS NOT NULL THEN 1
			ELSE 0
		END AS FLAG_RET,
		CASE
			WHEN PP.STATUS_PRAZO = 'ATENDIDO FORA DO PRAZO' THEN 1
			ELSE 0
		END AS FLAG_PRAZO,
		CASE
			WHEN UPS.Ch_Ups IN (
                'CORTE IMPRODUTIVO', 'CORTE NO MEDIDOR', 'SERVICO INVALIDO',
                'SERVICO IMPRODUTIVO', 'MT IMPRODUTIVA', 'EMERGENCIA IMPRODUTIVA',
                'RELIGACAO IMPRODUTIVA'
            ) THEN 1
			ELSE 0
		END AS FLAG_IMPRODUTIVA,
		CASE
			WHEN ups.ostipo_id = 'NR'
			AND ups.tipo_conclusao IN ('CASA FECHADA', 'ENDERECO NAO LOCALIZADO', 'NÃO LOCALIZADO',
                'INTERRUPCAO INDIVIDUAL POR DEFEITO INTERNO', 'LIGACAO CORTADA',
                'CONSUMIDOR CORTADO', 'DISJUNTOR DESLIGADO', 'NORMAL', 
                'DEFEITO INTERNO', 'OUTROS ESPECIFICAR (IMPROCEDENTE)',
                'SERVICO PREVENTIVO NAO PROGRAMADO', 'ENCONTRADO NORMAL'
            ) THEN 1
			ELSE 0
		END AS FLAG_IMPROCEDENCIA,
		CASE
			WHEN INC.REINCIDENTE_90_DIAS = 'S' THEN 1
			ELSE 0
		END AS FLAG_REINCIDENCIA,
		ups.data_dados
	FROM
		{{ ref('serv_exec_detalhado2') }} ups
	LEFT JOIN SB_PERFORMANCE.EQTL_PA.RETRABALHO ret ON
		to_char(ups.os_oper) = REGEXP_REPLACE(replace(RET.OS,'.00',''), '(\\d{4})-(\\d{1,2})/(\\d+)', '\\3-\\2-\\1')
		AND to_char(reT.oco_data_conclusao_origem, 'YYYYMM') = UPS.COMPETENCIA
	LEFT JOIN (
		SELECT
			*
		FROM
			{{ ref('prazo_sap_stc_pa') }}
		WHERE
			TIPO_NOTA NOT IN ('NR')) PP ON
		TRY_TO_NUMBER(pp.nota) = TRY_TO_NUMBER(replace(TRANSLATE(UPS.OS_OPER, '/-', ' '), ' ', ''))
		--left join  OWGSLCMR.GESTAO_DEC_FEC_MA DE ON to_char(DE.OCORRENCIA_ID)=UPS.OS_OPER AND to_char(DE.OCO_NUMERO)=UPS.OS
	LEFT JOIN {{ ref('det_reinc_trafo') }} INC ON
		OCO_NUMERO::INTEGER||'-'||TO_VARCHAR(TO_NUMBER(TO_CHAR(DATA,'MM')))||'-'||TO_CHAR(DATA,'YYYY') = UPS.OS_OPER
		AND inc.empresa = UPS.EMPRESA
	WHERE
		ups.competencia = {{ get_month_ref() }}
		AND ups.ch_ups NOT IN ('SERVICO INVALIDO')
		AND UPS.EMPRESA = 'EQTL_PA'
) T
