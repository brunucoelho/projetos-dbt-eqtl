{{ config(materialized='table') }}


WITH ultima_atribuicao AS (
    SELECT
        cd_movto_os_comercial,
        MAX(atribuicao_os_id) AS atribuicao_os_id
    FROM {{ source('OPER_PI', 'atribui_os_comercial') }}
    GROUP BY cd_movto_os_comercial
),
latitude_longitude AS (
    SELECT
        ua.cd_movto_os_comercial,
        MAX(mr.latitude) AS latitude,
        MAX(mr.longitude) AS longitude
    FROM ultima_atribuicao ua
    LEFT JOIN {{ source('OPER_PI', 'atribui_os_mensagem_retorno') }} mr
        ON mr.atribuicao_os_id = ua.atribuicao_os_id
        AND mr.macro_id = 59
    GROUP BY ua.cd_movto_os_comercial
)

SELECT
    'EQTL PI' AS empresa,
    current_timestamp AS data_carga,
    cc.dt_conclusao,
    ll.latitude,
    ll.longitude,
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
    SUBSTR(cc.ds_registro_atendimento, 0, 250) AS registro_exec,
    'SEM COMPONENTE DANIFICADO' AS componente_danificado,
    1000 AS tb_defeito_id,
    TO_NUMBER(
        CASE
            WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NOT NULL THEN cc.cd_tp_conclusao_os
            ELSE cc.cd_tp_conclusao_os
        END
    ) AS cod_conclusao,
    CASE
        WHEN cc.cd_tp_conclusao_os = '000' AND os.sssubtipo_id = 'VIS' THEN 'EXECUÇÃO DA VISTORIA'
        WHEN cc.cd_tp_conclusao_os = '003' AND os.ossubtipo_id = 'VIS' THEN 'SEM REDE E CLIENTE ACEITA FINANCIAMENTO'
        WHEN cc.cd_tp_conclusao_os = '004' AND os.sssubtipo_id = 'VIS' THEN 'SEM REDE E UC JA POSSUI PADRAO'
        WHEN cc.cd_tp_conclusao_os = '000' AND os.ostipo_id = 'LG' AND os.sssubtipo_id <> 'VIS' THEN 'CONCLUSÃO NORMAL'
        WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NOT NULL THEN cm.descricao
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0096' THEN 'RELIGAÇÃO IMPEDIDA/NÃO APRESE CONTA PAGA'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0095' THEN 'RELIGAÇÃO IMPEDIDA/AUTO RELIGADO'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0021' THEN 'UC FORA DE PADRAO OU INCOMPLETO'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0017' THEN 'OUTROS'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0015' THEN 'NÃO APRESENTOU FATURAS PAGAS'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0011' THEN 'NÃO LOCALIZADO'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0009' THEN 'OBSTÁCULO IMPEDE A EXECUÇÃO - SEM ACESSO'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0006' THEN 'CASA FECHADA-SEM ACESSO AO DISJUNTOR'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0002' THEN 'NÃO EXECUTADO'
        WHEN os.ostipo_id = 'RI' AND cc.cd_tp_conclusao_os = '0001' THEN lrel.lcrelig_descricao
        WHEN os.ostipo_id = 'CT' AND oc.tpoco_corte_id IS NULL THEN cm.descricao
        WHEN cc.cd_tp_conclusao_os = '999' THEN 'RECUSA DE SERVIÇO'
        WHEN atros_status = 'C' AND cc.dt_conclusao IS NULL THEN 'SOBRAS'
        ELSE cm.descricao
    END AS tipo_conclusao,
    2000 AS cod_subcausa,
    'Comercial' AS subcausa,
    CASE
        WHEN cc.cd_tp_conclusao_os IN (000) AND os.ostipo_id = 'MT' THEN 'P'
        WHEN cc.cd_tp_conclusao_os IN (1,3,4,5,6,7,9,19,23) AND os.ostipo_id = 'CT' THEN 'P'
        WHEN cc.cd_tp_conclusao_os IN (2,10,11,12,13,14,15,16,17,20,22,24.34) AND os.ostipo_id = 'CT' THEN 'I'
        WHEN cc.cd_tp_conclusao_os IN (14,18,21) AND os.ostipo_id = 'CT' THEN ''
        WHEN cc.cd_tp_conclusao_os = '999' THEN 'I'
        WHEN cm.tipo_conclusao = 'R' AND cm.code_medida_id NOT IN ('0017') AND cc.cd_tp_conclusao_os <> '0023' THEN 'I'
        WHEN cm.tipo_conclusao = 'R' AND cm.code_medida_id = '0017' THEN 'I'
        WHEN cm.tipo_conclusao = 'R' AND cc.cd_tp_conclusao_os = '0023' AND os.ostipo_id = 'CT' THEN 'P'
        WHEN cm.tipo_conclusao = 'N' THEN 'P'
        ELSE 'I'
    END AS tipo,
    rg.rel_descricao AS regional,
    pa3.pap_nome AS base,
    os.dt_solicitacao AS data_origem

FROM {{ source('OPER_PI', 'movto_os_comercial') }} os
LEFT JOIN latitude_longitude ll ON ll.cd_movto_os_comercial = os.cd_movto_os_comercial
LEFT JOIN {{ source('OPER_PI', 'bairro') }} br ON br.bairro_id = os.cd_bairro
LEFT JOIN {{ source('OPER_PI', 'localidade') }} lo ON lo.lc_id = br.lc_id
LEFT JOIN {{ source('OPER_PI', 'municipio') }} mp ON mp.mnc_id = lo.mnc_id
LEFT JOIN {{ source('OPER_PI', 'conclui_os_comercial') }} cc ON cc.cd_movto_os_comercial = os.cd_movto_os_comercial
LEFT JOIN {{ source('OPER_PI', 'tipo_ocorrencia_corte') }} oc ON oc.tpoco_corte_id = cc.cd_tp_ocorrencia_corte
LEFT JOIN {{ source('OPER_PI', 'atribui_os_comercial') }} ac ON ac.cd_movto_os_comercial = os.cd_movto_os_comercial
LEFT JOIN {{ source('OPER_PI', 'prefixo_turma') }} pt ON pt.prefixo_turma_id = ac.prefixo_turma_id
LEFT JOIN {{ source('OPER_PI', 'turma_os_comercial') }} tc ON tc.atribuicao_os_id = ac.atribuicao_os_id
LEFT JOIN {{ source('OPER_PI', 'base') }} bs ON bs.base_id = br.base_id
LEFT JOIN {{ source('OPER_PI', 'ponto_apoio') }} pa ON pa.codigo_pa = bs.codigo_pa
LEFT JOIN {{ source('OPER_PI', 'regiao_eletrica') }} rg ON rg.reg_eletrica_id = pa.reg_eletrica_id
LEFT JOIN {{ source('EQTL_PI', 'tipo_os_local_religacao') }} lr ON lr.tb_lcrelig_id = cc.cd_local_religacao
LEFT JOIN {{ source('OPER_PI', 'base') }} bs3 ON bs3.base_id = mp.base_id
LEFT JOIN {{ source('OPER_PI', 'ponto_apoio') }} pa3 ON pa3.codigo_pa = bs.codigo_pa
LEFT JOIN {{ source('OPER_PI', 'code_medida') }} cm ON cm.ossubtipo_id = os.ossubtipo_id AND cc.cd_tp_conclusao_os = cm.code_medida_id
LEFT JOIN {{ source('EQTL_PI', 'tipo_os_local_religacao') }} lrel ON lrel.tb_lcrelig_id = cc.cd_local_religacao
INNER JOIN ultima_atribuicao ua ON ua.cd_movto_os_comercial = os.cd_movto_os_comercial AND ac.atribuicao_os_id = ua.atribuicao_os_id

WHERE
    --{% if is_incremental() %}
    --    cc.dt_conclusao >= (SELECT MAX(cc.dt_conclusao) FROM {{ this }})
    --{% else %}
        cc.dt_conclusao >= TO_DATE('01/01/2023', 'DD/MM/YYYY') - 90
    --{% endif %}
    AND pt.prx_descricao NOT IN ('THEM0','THEM11','NORM0','NORM01','NORM02','METM0','METM78','SUM0','SUM01','SUDM0','OFS001')
    AND os.ostipo_id IN ('LG', 'TR', 'IS', 'MM', 'RI', 'DR', 'M1', 'MT')
    AND os.ossubtipo_id IN (
        'PENDCONX','SURAMA','MEDIAVAR','SUBSMED','SUBSRAM','EXSVGDIS','REATIVAC',
        'VIS','LDS','MDQUALAM','RELIGABD','LIGNOVBT','LIGEATBT','RELIGAAT',
        'INSPTECN','LIGREATI','DESLORAM','VDS','RLN','RLJ','RELIGABT','MUDMEDLC',
        'LIGPROVI','LIGANOVA','LGJ','RELIGASI','LUC','VLJ','TROCPABT','RLA',
        'TROCPAOT','RLA','RLA','RCI'
    )
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY os.cd_movto_os_comercial
    ORDER BY cm.tipo_conclusao
) = 1 AND tipo = 'P'
