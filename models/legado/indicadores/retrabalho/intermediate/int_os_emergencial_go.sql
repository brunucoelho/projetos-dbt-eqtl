{{ config(materialized='table') }}

SELECT
    'EQTL GO' AS Empresa,
    TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS data_carga,
    oc.oco_data_conclusao,
    br.bai_nome AS bairro,
    DECODE(oc.tb_tp_abrangencia, 'CR', 'CONSUMIDOR', 'TF', 'TRANSFORMADOR', 'CH', 'CHAVE', 'AL', 'ALIMENTADOR', 'SE', 'SUBESTACAO', oc.tb_tp_abrangencia) AS abrangencia,
    CAST(oc.ocorrencia_id AS FLOAT) AS os_oper,
    oc.oco_ano || '-' || oc.oco_mes || '/' || oc.oco_numero AS os,
    'NR' AS ostipo,
    CASE
        WHEN oc.tb_tp_abrangencia = 'CR' THEN 'IND'
        WHEN oc.tb_tp_abrangencia = 'NI' THEN 'IND'
        ELSE 'COL'
    END AS ossubtipo,
    mp.mnc_nome AS municipio,
    lo.loc_nome AS localidade,
    CAST(oc.cr_numero AS FLOAT) AS uc,
    pt.prx_descricao AS prefixo,
    SUBSTR(oc.oco_observacoes_atendimento,0,250) AS registro_exec,
    com.tcd_def_descricao AS componente_danificado,
    CAST(com.tb_defeito_id AS FLOAT) AS TB_DEFEITO_ID, 
    CAST(oc.tb_causa_id AS FLOAT) AS cod_conclusao,
    tc.tca_descricao AS tipo_conclusao,
    CAST(-1 AS FLOAT) AS Cod_Subcausa,
    '' AS subcausa,
    CASE
        WHEN oc.tb_tp_abrangencia IS NULL OR oc.tb_causa_id IS NULL THEN '?'
        WHEN oc.tb_causa_id IN (83, 14, 22, 23, 39, 56, 84, 85, 11, 34, 82) THEN 'I'
        ELSE 'P'
    END AS tipo,
    rg.rel_descricao AS regional,
    oc.oco_data_nr AS data_origem
FROM
    EQTLINFO_RAW.OPER_GO.ocorrencia oc
    INNER JOIN EQTLINFO_RAW.OPER_GO.tipo_de_causa tc ON tc.tb_causa_id = oc.tb_causa_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.historico_ocorrencia_turma ot ON ot.ocorrencia_id = oc.ocorrencia_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.historico_turma_plantao tp ON tp.hist_turma_plantao_id = ot.hist_turma_plantao_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.prefixo_turma pt ON pt.prefixo_turma_id = tp.prefixo_turma_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.base bs ON bs.base_id = oc.base_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.ponto_apoio pa ON pa.codigo_pa = bs.codigo_pa
    INNER JOIN EQTLINFO_RAW.OPER_GO.unidade_territorial ut ON ut.reg_eletrica_id = pa.reg_eletrica_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.regiao_eletrica rg ON rg.reg_eletrica_id = pa.reg_eletrica_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.bairro br ON br.bairro_id = oc.bairro_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.LOCALIDADE LO ON lo.lc_id = br.lc_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.municipio mp ON mp.mnc_id = lo.mnc_id
    LEFT JOIN EQTLINFO_RAW.OPER_GO.base bs3 ON bs3.base_id = mp.base_id
    INNER JOIN EQTLINFO_RAW.OPER_GO.ponto_apoio pa3 ON pa3.codigo_pa = bs.codigo_pa
    LEFT JOIN EQTLINFO_RAW.OPER_GO.code_medida t ON t.cdm_id = oc.tipo_conclusao
    LEFT JOIN EQTLINFO_RAW.OPER_GO.tipo_de_componente_danificado com ON com.tb_defeito_id = oc.tb_defeito_id
    LEFT JOIN EQTLINFO_RAW.OPER_GO.instalacao_operacao io ON oc.instalacao_id = io.instalacao_id
WHERE
    oc.oco_status = 'F'
    AND ot.hot_vi_status = 4
    AND oc.oco_data_conclusao >= TO_DATE('01/01/2023', 'DD/MM/YYYY') - 90
    --AND TRUNC(oc.oco_data_conclusao,'MM') BETWEEN  add_months(trunc(sysdate,'MM'),-3) AND trunc(sysdate,'MM')

