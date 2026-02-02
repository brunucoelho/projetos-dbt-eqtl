SELECT *
FROM
  (SELECT 
  		CURRENT_TIMESTAMP DATA_ETL,
                    a.*
   FROM
     (SELECT c.*,
             CASE
                 WHEN OS_ANTERIOR IS NOT NULL
                      AND IMPROCEDENTE <> 1
                      AND IMPROCEDENTE_R <> 1 THEN 1
                 ELSE 0
             END REINCIDENTE,
        CASE WHEN OS_ANTERIOR IS NOT NULL THEN 1
			       ELSE 0
        END REIN_COM_IMP
      FROM
        (SELECT a.*,
                ROW_NUMBER() OVER (PARTITION BY INSTALACAO, ID_INTERNO
                                   ORDER BY DT_CONCLUSAO_R DESC) RN
         FROM
           (SELECT *
            FROM
              (SELECT 
              DECODE(TX_STATE,'AL','EQTL_AL','AP','EQTL_AP','MA','EQTL_MA','PA','EQTL_PA','PI','EQTL_PI','GO','EQTL_GO','RS','EQTL_RS') EMPRESA,
              		ac.NB_ID ID_INTERNO,
                      ac.TX_OS OS,
                      ac.TX_TEXT_EQ_TIPOABRANGENCIA ABRANGENCIA,
                      NVL(TO_CHAR(ac.TX_EQ_INSTALACAO), ac.INSTALACAO_COM_DEFEITO) INSTALACAO,
                      ac.TX_RESOURCEEXTERNALID PREFIXO,
                      DATEADD(MINUTE, NB_DURATION, DATEADD(HOUR, -3, DT_ESTIMATEDTIMEARRIVAL)) DT_CONCLUSAO,
                      TX_TEXT_EQ_TIPODECAUSATEXT CAUSA,
                      CASE
                          WHEN TX_TEXT_EQ_TIPODECAUSATEXT IN ('NORMAL',
                                                              'CASA FECHADA',
                                                              'LIGAÇÃO CORTADA',
                                                              'ENDEREÇO NAO LOCALIZADO',
                                                              'DESLIGAMENTO PROGRAMADO COLETIVO',
                                                              'DESLIGAMENTO PROGRAMADO INDIVIDUAL',
                                                              'INTERRUPÇÃO INDIVIDUAL POR DEFEITO INTERNO',
                                                              'SERVIÇO PREVENTIVO NÃO PROGRAMADO') THEN 1
                          ELSE 0
                      END IMPROCEDENTE
               FROM EQTLINFO_RAW.SIGA.TB_OFSC_ACTIVITIES_RT ac
               WHERE ac.TX_EQ_TIPONOTA = 'NR'
                 AND ac.TX_TEXT_EQ_TIPOABRANGENCIA = 'CR'
                 AND TX_STATUS IN ('completed')
                 AND NVL(TO_CHAR(ac.TX_EQ_INSTALACAO), ac.INSTALACAO_COM_DEFEITO) IS NOT NULL
                 AND NVL(TO_CHAR(ac.TX_EQ_INSTALACAO), ac.INSTALACAO_COM_DEFEITO) <> '0'
                 AND ac.TX_OS IS NOT NULL
                 AND TRUNC(DATEADD(MINUTE, NB_DURATION, DATEADD(HOUR, -3, DT_ESTIMATEDTIMEARRIVAL)),'MM') = TO_DATE({{ get_month_ref() }},'YYYYMM')
                 AND TX_STATE IN ('AL','AP','MA','PA','PI','RS','GO')) A
            LEFT JOIN
              (SELECT ac.NB_ID ID_INTERNO_R,
                      ac.TX_OS OS_ANTERIOR,
                      ac.TX_RESOURCEEXTERNALID PREFIXO_ANTERIOR,
                      NVL(TO_CHAR(ac.TX_EQ_INSTALACAO), ac.INSTALACAO_COM_DEFEITO) INSTALACAO_R,
                      DATEADD(MINUTE, NB_DURATION, DATEADD(HOUR, -3, DT_ESTIMATEDTIMEARRIVAL)) DT_CONCLUSAO_R,
                      TX_TEXT_EQ_TIPODECAUSATEXT CAUSA_ANTERIOR,
                      CASE
                          WHEN TX_TEXT_EQ_TIPODECAUSATEXT IN ('NORMAL',
                                                              'CASA FECHADA',
                                                              'LIGAÇÃO CORTADA',
                                                              'ENDEREÇO NAO LOCALIZADO',
                                                              'DESLIGAMENTO PROGRAMADO COLETIVO',
                                                              'DESLIGAMENTO PROGRAMADO INDIVIDUAL',
                                                              'INTERRUPÇÃO INDIVIDUAL POR DEFEITO INTERNO',
                                                              'SERVIÇO PREVENTIVO NÃO PROGRAMADO') THEN 1
                          ELSE 0
                      END IMPROCEDENTE_R
               FROM EQTLINFO_RAW.SIGA.TB_OFSC_ACTIVITIES_RT ac
               WHERE ac.TX_EQ_TIPONOTA = 'NR'
                 AND ac.TX_TEXT_EQ_TIPOABRANGENCIA = 'CR'
                 AND ac.TX_OS IS NOT NULL
                 AND TX_STATUS IN ('completed')
                 AND NVL(TO_CHAR(ac.TX_EQ_INSTALACAO), ac.INSTALACAO_COM_DEFEITO) IS NOT NULL
                 AND NVL(TO_CHAR(ac.TX_EQ_INSTALACAO), ac.INSTALACAO_COM_DEFEITO) <> '0'
                 AND DATEADD(MINUTE, NB_DURATION, DATEADD(HOUR, -3, DT_ESTIMATEDTIMEARRIVAL))::DATE >= DATEADD(DAY, -91, TO_DATE({{ get_month_ref() }},'YYYYMM')) AND TRUNC(DATEADD(MINUTE, NB_DURATION, DATEADD(HOUR, -3, DT_ESTIMATEDTIMEARRIVAL)),'MM') <= TO_DATE({{ get_month_ref() }},'YYYYMM')) b ON a.INSTALACAO = b.INSTALACAO_R
            AND b.DT_CONCLUSAO_R >= DATEADD(DAY, -90, a.DT_CONCLUSAO)
            AND b.DT_CONCLUSAO_R < (a.DT_CONCLUSAO)
            AND a.ID_INTERNO != b.ID_INTERNO_R) a) c
      WHERE RN = 1) A)