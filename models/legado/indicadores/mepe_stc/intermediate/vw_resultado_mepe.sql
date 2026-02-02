SELECT 
    x.*,
    CASE 
        WHEN x.MEPE_FINAL >= 90 THEN 'A'
        WHEN x.MEPE_FINAL >= 75 THEN 'B'
        WHEN x.MEPE_FINAL >= 40 THEN 'C'
        WHEN x.MEPE_FINAL < 40 THEN 'D' 
    END CLASSE_MEPE_FINAL,

    CASE 
        WHEN x.MEPE_FINAL_CAMPANHA >= 90 THEN 'A'
        WHEN x.MEPE_FINAL_CAMPANHA >= 75 THEN 'B'
        WHEN x.MEPE_FINAL_CAMPANHA >= 40 THEN 'C'
        WHEN x.MEPE_FINAL_CAMPANHA < 40 THEN 'D' 
    END CLASSE_MEPE_FINAL_CAMPANHA

FROM (
    SELECT
        M.*,

        -- cálculo do MEPE_FINAL
        CASE 
            WHEN M.EMPRESA IN ('EQTL_AP','EQTL_RS','EQTL_GO') AND M.TIPO_EQP IN ('LIGACAO_NOVA','RELIGACAO')  
                THEN (M.MEPE_UPS*0.4) + (M.MEPE_RETR_COM*0.3) + (M.MEPE_PRAZO*0.3) /* + (M.MEPE_PRIM_VIS*0.3) PESOS REDISTRIBUIDOS */

            WHEN M.TIPO_EQP = 'ATENDIMENTO_EMERGENCIAL' 
                THEN (M.MEPE_UPS*0.4) + (M.MEPE_REINCIDENCIA*0.3) + (M.MEPE_RETRA*0.3)
            WHEN M.TIPO_EQP = 'MULTIFUNCIONAL'
                THEN (M.MEPE_UPS*0.4) + (M.MEPE_REINCIDENCIA*0.3) + (M.MEPE_RETRA*0.3)
            WHEN M.TIPO_EQP IN ('LIGACAO_NOVA','RELIGACAO') 
                 OR M.SERV_CAMPO IN ('RELIGA CARRO','RELIGA MOTO')
                THEN (M.MEPE_UPS*0.3) + (M.MEPE_RETR_COM*0.2) + (M.MEPE_PRAZO*0.2) + (M.MEPE_PRIM_VIS*0.3)
        END MEPE_FINAL,

        -- cálculo do MEPE_FINAL_CAMPANHA
        CASE 
            WHEN M.EMPRESA IN ('EQTL_AP','EQTL_RS','EQTL_GO') AND (M.TIPO_EQP IN ('LIGACAO_NOVA','RELIGACAO') 
                 OR M.SERV_CAMPO IN ('RELIGA CARRO','RELIGA MOTO'))
                THEN (M.MEPE_UPS*0.4) + (M.MEPE_RETR_COM*0.3) + (M.MEPE_PRAZO*0.3) /* + (M.MEPE_PRIM_VIS*0.3) PESOS REDISTRIBUIDOS */

            WHEN M.TIPO_EQP = 'ATENDIMENTO_EMERGENCIAL' 
                THEN (M.MEPE_REINCIDENCIA*0.5) + (M.MEPE_RETRA*0.5)
            WHEN M.TIPO_EQP = 'MULTIFUNCIONAL'
                THEN (M.MEPE_REINCIDENCIA*0.5) + (M.MEPE_RETRA*0.5)
            WHEN M.TIPO_EQP IN ('LIGACAO_NOVA','RELIGACAO') 
                 OR M.SERV_CAMPO IN ('RELIGA CARRO','RELIGA MOTO')
                THEN (M.MEPE_UPS*0.3) + (M.MEPE_RETR_COM*0.2) + (M.MEPE_PRAZO*0.2) + (M.MEPE_PRIM_VIS*0.3)
        END MEPE_FINAL_CAMPANHA,

        -- cálculo de trimestre
        CASE 
            WHEN M.mes_concl IN ('01','02','03') THEN '01º_TRIMESTRE'
            WHEN M.mes_concl IN ('04','05','06') THEN '02º_TRIMESTRE'
            WHEN M.mes_concl IN ('07','08','09') THEN '03º_TRIMESTRE'
            WHEN M.mes_concl IN ('10','11','12') THEN '04º_TRIMESTRE'
        END TRIMESTRE

    FROM (
        SELECT 
            ups.empresa,
            ups.regional_prx,
            ups.polo_prx,
            ups.equipe,
            ups.processo_prx,
            CASE 
                WHEN ups.serv_campo IN ('RELIGA CARRO','RELIGA MOTO') THEN 'LIGACAO_NOVA'
                WHEN ups.tipo_eqp = 'MULTIFUNCIONAL' THEN 'ATENDIMENTO_EMERGENCIAL'
                WHEN ups.tipo_eqp = 'RELIGACAO' THEN 'LIGACAO_NOVA'
                ELSE ups.tipo_eqp 
            END tipo_eqp,
            ups.serv_campo,
            ups.fornecedor,
            ups.competencia,
            ups.mes_concl,
            ups.mes_ano,
            ups.ano_concl,
            ups.realizado_mensal,
            ups.meta_mensal,
            ups.media_ups_mes,
            ups.dias_uteis,
            ups.ader_meta_ups AS ADERENCIA_UPS,

            CASE 
                WHEN ups.ader_meta_ups >= 91 THEN 'A' 
                WHEN ups.ader_meta_ups >= 75 THEN 'B' 
                WHEN ups.ader_meta_ups >= 41 THEN 'C' 
                WHEN ups.ader_meta_ups < 41 THEN 'D' 
                ELSE ''  
            END classe_mepe_ups,

            NVL(RET.PERC_RETRA,0) PERC_RETRA,
            NVL(RET.META,0) META_RETRA,
            NVL(RET.ATINGIMENTO,0) ADERENCIA_RETRABALHO, 
            RET.CLASSE CLASSE_MEPE_RETRABALHO,  

            NVL(PRZ.Perc,0) PERC_PRAZO,
            100 META_PRAZO,
            NVL(PRZ.Perc,0) ADERENCIA_PRAZO,
            PRZ.CLASSE_MEPE_PRAZO CLASSE_MEPE_PRAZO,

            NVL(PRI.PERC,0) PERC_PRIM,
            NVL(PRI.META_PRIMEIRA,0) META_PRIMEIRA,
            NVL(PRI.ADERENCIA,0) ADERENCIA_PRIM_VIS,
            PRI.CLASSE_MEPE_P_VISITA CLASSE_MEPE_P_VISITA,

            NVL(REI.QTD_REINCIDENTES,0) QTD_REINCIDENTES,
            NVL(REI.QTD_TOTAL,0) QTD_TOTAL_REINCI,
            NVL(REI.META,0) META_REINC,
            NVL(REI.PERCENTUAL,0) PERC_REINC,
            NVL(REI.ATINGIMENTO,0) ADERENCIA_REINC, 
            COALESCE(REI.CLASSE_REINCIDENCIA,'A') CLASSE_MEPE_REINC,

            NVL(REC.QTD_RETRA,0) QTD_ORI_RETR_COM,
            NVL(REC.QTD_TOTAL,0) QTD_TOTAL_RETR_COM,
            NVL(REC.PERC_RETRA,0) PERC_RETRA_COM,
            NVL(REC.META,0) META_RETR_COM,
            NVL(REC.ATINGIMENTO,0) ADERENCIA_RETR_COM,
            REC.CLASSE CLASSE_MEPE_RETR_COM,

            CASE WHEN ups.ader_meta_ups > 100 THEN 100 ELSE NVL(ups.ader_meta_ups,0) END MEPE_UPS,

            CASE 
                WHEN RET.ATINGIMENTO > 140 THEN 0 
                WHEN RET.ATINGIMENTO > 100 THEN 30
                WHEN RET.ATINGIMENTO > 85 THEN 70 
                WHEN RET.ATINGIMENTO <= 85 THEN 100 
                ELSE 0  
            END MEPE_RETRA,

            CASE 
                WHEN NVL(PRZ.Perc,0) >= 100 THEN 100 
                WHEN NVL(PRZ.Perc,0) >= 98 THEN 70 
                WHEN NVL(PRZ.Perc,0) >= 96 THEN 30 
                WHEN NVL(PRZ.Perc,0) < 96 THEN 0 
                ELSE 0 
            END MEPE_PRAZO,

            CASE 
                WHEN NVL(PRI.ADERENCIA,0) >= 100 THEN 100 
                WHEN NVL(PRI.ADERENCIA,0) >= 95 THEN 70 
                WHEN NVL(PRI.ADERENCIA,0) > 90 THEN 30 
                WHEN NVL(PRI.ADERENCIA,0) <= 90 THEN 0 
                ELSE 0 
            END MEPE_PRIM_VIS,

            COALESCE(REI.MEPE_REINCIDENCIA,100) MEPE_REINCIDENCIA,

            CASE 
                WHEN REC.ATINGIMENTO = 0 THEN 100
                WHEN NVL(REC.ATINGIMENTO,0) > 100 THEN 0 
                WHEN NVL(REC.ATINGIMENTO,0) > 80 THEN 30 
                WHEN NVL(REC.ATINGIMENTO,0) > 60 THEN 70 
                WHEN NVL(REC.ATINGIMENTO,0) <= 60 THEN 100 
                WHEN NVL(REC.ATINGIMENTO,0) IS NULL THEN 100
                ELSE 0 
            END MEPE_RETR_COM,

            CASE WHEN EXP.EXPURGAR = 'SIM' THEN EXP.EXPURGAR ELSE 'NAO' END EXPURGAR,

            ups.atualizacao

        FROM {{ ref('gp_mepe_ups') }} ups
        LEFT JOIN {{ ref('gp_mepe_prazo') }} prz 
               ON prz.empresa = ups.empresa 
              AND prz.equipe = ups.equipe 
              AND prz.competencia = ups.competencia
        LEFT JOIN {{ ref('gp_mepe_primvisi') }} pri 
               ON pri.empresa = ups.empresa 
              AND pri.prefixo = ups.equipe 
              AND pri.mes_competencia = ups.competencia
        LEFT JOIN {{ ref('gp_mepe_retra') }} ret 
               ON ret.empresa = ups.empresa 
              AND ret.prefixo = ups.equipe 
              AND ret.competencia = ups.competencia
        LEFT JOIN {{ ref('gp_mepe_reinc') }} rei 
               ON rei.distribuidora = ups.empresa 
              AND rei.equipe = ups.equipe 
              AND rei.competencia = ups.competencia
        LEFT JOIN {{ ref('gp_mepe_retra_com') }} rec 
               ON rec.empresa = ups.empresa 
              AND rec.prefixo = ups.equipe 
              AND rec.competencia = ups.competencia
        LEFT JOIN SB_PERFORMANCE.EQTL_CORP.gstc_expurgo exp 
               ON exp.chave = ups.empresa||'-'||ups.equipe||'-'||ups.competencia

        WHERE ups.processo_prx NOT IN ('SUPORTE','PERDAS','SEED MONEY','PI RAMAL','SEED MONEY 4X4','LINHA MORTA','TATICA',
                                       'LINHA VIVA','PODA','GRUPO A','EQUIPAMENTO','FISCAL','MANUTENCAO')
          AND ups.tipo_eqp NOT IN ('PROPRIO','MANUTENCAO','FISCAL','PODA','QUALIDADE','NAO_LIDOS','PI_DE_RAMAL','OBRAS')
          AND ups.serv_campo NOT IN ('CORTE LEVE','CORTE MOTO','CORTE 4X4')
          AND to_date(ups.competencia,'YYYYMM') = TO_DATE({{ get_month_ref() }},'YYYYMM')
    ) M
) x
WHERE x.expurgar = 'NAO'
