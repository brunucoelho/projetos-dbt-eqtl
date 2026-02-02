WITH Reincidencias AS (
    SELECT 
        oc.oco_data_nr,
        ip.iop_num,
        COUNT(*) OVER (
            PARTITION BY ip.iop_num 
            ORDER BY oc.oco_data_nr 
            RANGE BETWEEN INTERVAL '90 days' PRECEDING AND CURRENT ROW
        ) AS reinc_count
    FROM EQTLINFO_RAW.OPER_GO.ocorrencia oc
    LEFT JOIN EQTLINFO_RAW.OPER_GO.INSTALACAO_PERMANENTE ip 
           ON oc.instalacao_id = ip.instalacao_id
    WHERE 
        oc.TB_NATUREZA_ID = 1
        AND oc.OCO_INTERRUPCAO = 'S'
)
SELECT 
    'EQTL_GO' AS EMPRESA,
    CURRENT_TIMESTAMP data_carga,
    rg.rel_descricao AS regional,
    pa.pap_nome AS SECCIONAL,
    oc.oco_data_nr AS DATA,
    PT.PRX_DESCRICAO,
    oc.oco_data_conclusao AS data_conclusao,
    TN.TNA_DESCRICAO NATUREZA,
    oc.oco_numero,
    tc.TCA_DESCRICAO causa,
    oc.tb_tp_abrangencia abrangencia,   	
    ip.iop_num AS PDF,
    DECODE(oc.tb_tp_abrangencia, 'CR', 'CONSUMIDOR', 'TF', 'TRANSFORMADOR', 'CH', 'CHAVE', 'AL', 'ALIMENTADOR', 'SE', 'SUBESTACAO', oc.tb_tp_abrangencia) AS TIPO_EQP,
    NULL CHI,
    COUNT(DISTINCT con.cr_numero) AS CLIE,
    r.reinc_count AS n_reinc,
    
    CASE
        WHEN r.reinc_count >= 2 THEN 'S'
        ELSE 'N'
    END AS reincidente_90_dias
    
FROM
     EQTLINFO_RAW.OPER_GO.ocorrencia oc
    LEFT JOIN  EQTLINFO_RAW.OPER_GO.TIPO_DE_NATUREZA TN ON TN.TB_NATUREZA_ID=OC.TB_NATUREZA_ID
    LEFT JOIN  EQTLINFO_RAW.OPER_GO.tipo_de_causa tc ON tc.tb_causa_id = oc.tb_causa_id
    LEFT JOIN  EQTLINFO_RAW.OPER_GO.historico_ocorrencia_turma ot ON ot.ocorrencia_id = oc.ocorrencia_id
    LEFT JOIN  EQTLINFO_RAW.OPER_GO.historico_turma_plantao tp ON tp.hist_turma_plantao_id = ot.hist_turma_plantao_id
    LEFT JOIN  EQTLINFO_RAW.OPER_GO.prefixo_turma pt ON pt.prefixo_turma_id = tp.prefixo_turma_id
    INNER JOIN  EQTLINFO_RAW.OPER_GO.base bs ON bs.base_id = oc.base_id
    INNER JOIN  EQTLINFO_RAW.OPER_GO.ponto_apoio pa ON pa.codigo_pa = bs.codigo_pa
    INNER JOIN  EQTLINFO_RAW.OPER_GO.unidade_territorial ut ON ut.reg_eletrica_id = pa.reg_eletrica_id
    INNER JOIN  EQTLINFO_RAW.OPER_GO.regiao_eletrica rg ON rg.reg_eletrica_id = pa.reg_eletrica_id
    INNER JOIN  EQTLINFO_RAW.OPER_GO.bairro br ON br.bairro_id = oc.bairro_id
    INNER JOIN  EQTLINFO_RAW.OPER_GO.municipio mp ON mp.mnc_id = oc.MNC_id
    INNER JOIN  EQTLINFO_RAW.OPER_GO.consumidor con ON con.INSTALACAO_ID = oc.INSTALACAO_ID
    LEFT JOIN  EQTLINFO_RAW.OPER_GO.tipo_de_componente_danificado com ON com.tb_defeito_id = oc.tb_defeito_id
    LEFT JOIN  EQTLINFO_RAW.OPER_GO.INSTALACAO_PERMANENTE ip ON oc.instalacao_id = ip.instalacao_id
    LEFT JOIN Reincidencias r ON (
        r.iop_num = ip.iop_num
        AND r.oco_data_nr = oc.oco_data_nr
    )
WHERE
    oc.oco_status = 'F'
    AND ot.hot_vi_status = 4
    AND TRUNC(oc.oco_data_conclusao, 'MM') = TO_DATE({{ get_month_ref() }} , 'YYYYMM')
    AND oc.TB_NATUREZA_ID = 1
    AND oc.OCO_INTERRUPCAO = 'S'
    AND pa.pap_nome NOT LIKE 'APOIO'
    AND oc.tb_tp_abrangencia = 'TF'
    --AND ip.iop_num NOT LIKE '__21%'
    --AND ip.iop_num = 'BV21466305'
GROUP BY
    'EQTL_GO',
    rg.rel_descricao,
    pa.pap_nome,
    oc.oco_data_nr,
    PT.PRX_DESCRICAO,
    oc.oco_data_conclusao,
    TN.TNA_DESCRICAO,
    oc.oco_numero,
    tc.TCA_DESCRICAO,
    oc.tb_tp_abrangencia,
    ip.iop_num,
    DECODE(oc.tb_tp_abrangencia, 'CR', 'CONSUMIDOR', 'TF', 'TRANSFORMADOR', 'CH', 'CHAVE', 'AL', 'ALIMENTADOR', 'SE', 'SUBESTACAO', oc.tb_tp_abrangencia),
    oc.ocorrencia_id,
    r.reinc_count