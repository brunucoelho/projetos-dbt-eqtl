{{ config(materialized='table') }}

SELECT
    *
FROM
(
    SELECT
        'EQTL PA' AS empresa,
        ns.tipo_nota AS ostipo,
        CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_NTZ) AS data_carga,
        CAST(ns.nota AS FLOAT) AS os_oper,
        TO_CHAR(ns.data_criacao, 'YYYY') || '-' || TO_CHAR(ns.data_criacao, 'MM') || '/' || ns.nota AS os,
        CAST(tc.latitude AS FLOAT) AS latitude,
        CAST(tc.longitude AS FLOAT) AS longitude,
        tc.bairro,
        'COMERCIAL' AS abrangencia,
        NULL AS componente_danificado,
        CAST(NULL AS FLOAT) AS tb_defeito_id,
        ns.data_criacao AS data_origem,
        CASE
            WHEN mns.codigo_medida IN ('0001', '0002')
                 OR nf.irregularidade IN (
                     '109','115','154','155','175','188',
                     '201','204','214','215','221','307',
                     '308','311'
                 ) THEN 'P'
            WHEN aplicacao_ramal_conc = 'SIM' THEN 'P'
            ELSE 'I'
        END AS tipo,
        CASE
            WHEN mns.codigo_medida IN ('0001','0002')
                 OR nf.irregularidade IN (
                     '109','115','154','155','175','188',
                     '201','204','214','215','221','307',
                     '308','311'
                 ) THEN 1
            ELSE 0
        END AS med_trocado,
        nf.aplicacao_ramal_conc,
        ns.data_encerramento AS oco_data_conclusao,
        vn.nr_viatura AS prefixo,
        tc.regional,
        tc.municipio,
        tc.localidade,
        CAST(ns.instalacao AS FLOAT) AS uc,
        ns.grupo_codes AS ossubtipo,
        TRY_CAST(nf.irregularidade AS FLOAT) AS cod_conclusao,
        ir.desc_irregularidade AS tipo_conclusao,
        CAST(2000 AS FLOAT) AS cod_subcausa,
        'COMERCIAL' AS subcausa,
        SUBSTR(nf.observacoes, 0, 250) AS registro_exec
    FROM {{ source('EQTL_PA', 'notas_servicos') }} ns
    LEFT JOIN {{ source('EQTL_PA', 'visitas_notas') }} vn 
        ON vn.nota = ns.nota
    LEFT JOIN {{ source('EQTL_PA', 'info_gerais_notas') }} ign 
        ON ign.nota = ns.nota
    LEFT JOIN {{ source('EQTL_PA', 'tab_cadastro') }} tc 
        ON tc.instalacao = ns.instalacao
    LEFT JOIN {{ source('EQTL_PA', 'notas_fiscalizacao') }} nf 
        ON nf.nota = ns.nota
    LEFT JOIN {{ source('EQTL_PA', 'equipa_i_notas') }} e 
        ON ns.mandante = e.mandante AND ns.nota = e.nota
    LEFT JOIN {{ source('EQTL_PA_PERFORMANCE', 'tab_cod_irregularidade') }} ir 
        ON ir.irregularidade = TRY_TO_NUMBER(nf.irregularidade)
    LEFT JOIN {{ source('EQTL_PA', 'medidas_notas_servicos') }} mns 
        ON mns.nota = ns.nota
        AND mns.tipo_nota = ns.tipo_nota
        AND mns.data_encerramento_nota = ns.data_alteracao
        AND mns.grupo_medida = 'ALTEEQUI'

    WHERE
        ns.tipo_nota IN ('FS')
        AND ns.data_encerramento >= TO_DATE('01/01/2023', 'DD/MM/YYYY') - 90
        AND ns.status_ccs IN ('FINL')
        AND ns.codificacao NOT IN ('MDFC')
    GROUP BY
        ns.tipo_nota,
        ns.nota,
        tc.latitude,
        tc.longitude,
        tc.bairro,
        ns.data_criacao,
        CASE
            WHEN mns.codigo_medida IN ('0001','0002')
                 OR nf.irregularidade IN (
                     '109','115','154','155','175','188',
                     '201','204','214','215','221','307',
                     '308','311'
                 ) THEN 'P'
            WHEN aplicacao_ramal_conc = 'SIM' THEN 'P'
            ELSE 'I'
        END,
        CASE
            WHEN mns.codigo_medida IN ('0001','0002')
                 OR nf.irregularidade IN (
                     '109','115','154','155','175','188',
                     '201','204','214','215','221','307',
                     '308','311'
                 ) THEN 1
            ELSE 0
        END,
        nf.aplicacao_ramal_conc,
        ns.data_encerramento,
        vn.nr_viatura,
        tc.regional,
        tc.municipio,
        tc.localidade,
        CAST(ns.instalacao AS FLOAT),
        ns.grupo_codes,
        nf.irregularidade,
        ir.desc_irregularidade,
        nf.observacoes
)
WHERE
    med_trocado = 1
    OR aplicacao_ramal_conc = 'SIM'
