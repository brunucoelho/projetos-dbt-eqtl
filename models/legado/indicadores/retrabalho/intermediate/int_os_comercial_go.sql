{{ config(materialized='table') }}


SELECT
	'EQTL GO' AS Empresa,
			TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS DATA_CARGA,
            dt_conclusao AS OCO_DATA_CONCLUSAO,
            bairro,
            abrangencia,
            CAST(os_oper AS FLOAT) AS OS_OPER,
            os,
            ostipo_id AS OSTIPO,
            ossubtipo_id AS OSSUBTIPO,
            municipio,
            localidade,
            CAST(uc AS FLOAT) AS UC,
            prefixo,
            registro_exec,
            componente_danificado,
            CAST(tb_defeito_id AS FLOAT) AS TB_DEFEITO_ID,
            REGEXP_REPLACE(COD_CONCLUSAO, '[A-Z]', '') AS cod_conclusao,
            tipo_conclusao,
            CAST(Cod_Subcausa AS FLOAT) AS COD_SUBCAUSA,
            subcausa,
            TIPO,
            regional,
            data_origem
FROM ( 

WITH latest_atribui_os_comercial AS (
    SELECT
        ac2.cd_movto_os_comercial,
        MAX(ac2.atribuicao_os_id) AS max_atribuicao_os_id
    FROM
        EQTLINFO_RAW.OPER_GO.atribui_os_comercial ac2
    GROUP BY
        ac2.cd_movto_os_comercial
)
SELECT
    'EQTL GO' AS Empresa,
    ac.atros_status,
   	TO_TIMESTAMP_NTZ(CURRENT_TIMESTAMP) AS data_carga,
    cc.dt_conclusao,
    br.bai_nome AS bairro,
    'OS_COMERCIAL' AS abrangencia,
    os.cd_movto_os_comercial AS os_oper,
    TO_CHAR(os.dt_programacao_os, 'MM') || '/' || TO_CHAR(os.dt_programacao_os, 'YYYY') || '-' || os.nr_os AS os,
    os.ostipo_id,
    os.ossubtipo_id,
    mp.mnc_nome AS municipio,
    lo.loc_nome AS localidade,
    TRUNC(os.nr_uc, 0) AS uc,
    pt.prx_descricao AS prefixo,
    substr(cc.ds_registro_atendimento,0,250) AS registro_exec,
    'SEM COMPONENTE DANIFICADO' AS componente_danificado,
    1000 AS tb_defeito_id,
    CASE
        WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NOT NULL THEN cc.cd_tp_conclusao_os
        ELSE cc.cd_tp_conclusao_os
    END AS cod_conclusao,
    CASE
        WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NOT NULL THEN cm.descricao
        --WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0001' THEN lrel.lcrelig_descricao
        WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NULL THEN cm.descricao
        WHEN cc.cd_tp_conclusao_os = '999' THEN 'RECUSA DE SERVIÇO'
        WHEN atros_status = 'C' AND cc.dt_conclusao IS NULL THEN 'SOBRAS'
        ELSE cm.descricao
    END AS tipo_conclusao,
    2000 AS Cod_Subcausa,
    'Comercial' AS subcausa,
    CASE
        WHEN cm.descricao LIKE '%EXECUTADO%' OR cm.descricao IN ('APROVADO E LIGADO', 'CORTE NO POSTE') THEN 'P'
        ELSE 'I'
    END AS tipo,
    rg.rel_descricao AS regional,
    os.dt_solicitacao AS data_origem,
    ROW_NUMBER() OVER (PARTITION BY os.cd_movto_os_comercial ORDER BY cm.tipo_conclusao) AS RN
FROM
    EQTLINFO_RAW.OPER_GO.movto_os_comercial os
    LEFT JOIN EQTLINFO_RAW.OPER_GO.bairro br ON br.bairro_id = os.cd_bairro
    LEFT JOIN EQTLINFO_RAW.OPER_GO.LOCALIDADE lo ON lo.lc_id = br.lc_id
    LEFT JOIN EQTLINFO_RAW.OPER_GO.municipio mp ON mp.mnc_id = lo.mnc_id
    LEFT JOIN EQTLINFO_RAW.OPER_GO.conclui_os_comercial cc ON cc.cd_movto_os_comercial = os.cd_movto_os_comercial
    LEFT JOIN EQTLINFO_RAW.OPER_GO.tipo_ocorrencia_corte oc ON oc.tpoco_corte_id = cc.cd_tp_ocorrencia_corte
    LEFT JOIN EQTLINFO_RAW.OPER_GO.atribui_os_comercial ac ON ac.cd_movto_os_comercial = os.cd_movto_os_comercial
    LEFT JOIN EQTLINFO_RAW.OPER_GO.prefixo_turma pt ON pt.prefixo_turma_id = ac.prefixo_turma_id
    LEFT JOIN EQTLINFO_RAW.OPER_GO.turma_os_comercial tc ON tc.atribuicao_os_id = ac.atribuicao_os_id
    LEFT JOIN EQTLINFO_RAW.OPER_GO.base bs ON bs.base_id = br.base_id
    LEFT JOIN EQTLINFO_RAW.OPER_GO.ponto_apoio pa ON pa.codigo_pa = bs.codigo_pa
    LEFT JOIN EQTLINFO_RAW.OPER_GO.regiao_eletrica rg ON rg.reg_eletrica_id = pa.reg_eletrica_id
    --LEFT JOIN EQTLINFO_RAW.OPER_GO.tipo_os_local_religacao lr ON lr.tb_lcrelig_id = cc.cd_local_religacao
    --INNER JOIN EQTLINFO_RAW.OPER_GO.base bs3 ON bs3.base_id = mp.base_id
    --INNER JOIN EQTLINFO_RAW.OPER_GO.ponto_apoio pa3 ON pa3.codigo_pa = bs.codigo_pa
    LEFT JOIN EQTLINFO_RAW.OPER_GO.code_medida cm ON cm.ossubtipo_id = os.ossubtipo_id AND cc.cd_tp_conclusao_os = cm.code_medida_id
    --LEFT JOIN EQTLINFO_RAW.OPER_GO.tipo_os_local_religacao lrel ON lrel.tb_lcrelig_id = cc.cd_local_religacao
    --INNER JOIN latest_atribui_os_comercial laoc ON laoc.cd_movto_os_comercial = ac.cd_movto_os_comercial AND laoc.max_atribuicao_os_id = ac.atribuicao_os_id
    WHERE
    CC.DT_CONCLUSAO >= TO_DATE('01/01/2023','DD/MM/YYYY') - 90
    AND OS.OSTIPO_ID <> 'CT' AND OS.OSTIPO_ID <> 'DS'
    --TRUNC(cc.dt_conclusao,'MM') BETWEEN  add_months(trunc(sysdate,'MM'),-3) AND trunc(sysdate,'MM')
    )
    WHERE RN = 1  
    AND tipo = 'P'

