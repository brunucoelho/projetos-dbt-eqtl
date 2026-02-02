{{ config(
    materialized='table'
) }}

SELECT
    *
FROM
    (
        SELECT
            'EQTL AP' AS EMPRESA,
            ns.tipo_nota                   ostipo,
            current_timestamp data_carga,
            ns.nota                        os_oper,
            to_char(ns.data_criacao, 'YYYY')
            || '-'
            || to_char(ns.data_criacao, 'MM')
            || '/'
            || ns.nota                     os,
            CAST(tc.latitude AS varchar) AS latitude,
            CAST(tc.longitude AS varchar) AS longitude,
            tc.bairro,
            'COMERCIAL' AS ABRANGENCIA,
            null AS COMPONENTE_DANIFICADO,
            null AS TB_DEFEITO_ID,
            ns.data_criacao                AS data_origem,
            CASE
                WHEN mns.codigo_medida IN ( '0001', '0002' )
                     OR nf.irregularidade IN (
                        '109','115','154','155','175',
                        '188','201','204','214','215',
                        '221','307','308','311'
                     ) THEN 'P'
                WHEN aplicacao_ramal_conc = 'SIM' THEN 'P'
                ELSE 'I'
            END AS tipo,
            CASE
                WHEN mns.codigo_medida IN ( '0001', '0002' )
                     OR nf.irregularidade IN (
                        '109','115','154','155','175',
                        '188','201','204','214','215',
                        '221','307','308','311'
                     ) THEN 1
                ELSE 0
            END AS med_trocado,
            nf.aplicacao_ramal_conc,
            ns.data_encerramento           AS oco_data_conclusao,
            vn.nr_viatura as prefixo,
            tc.regional,
            tc.municipio,
            tc.localidade,
            trunc(ns.instalacao,0)        uc,
            ns.grupo_codes                 AS ossubtipo,
            nf.irregularidade              AS cod_conclusao,
            ir.desc_irregularidade         tipo_conclusao,
            2000 AS cod_subcausa,
            'COMERCIAL' AS subcausa,
            substr(nf.observacoes,0,250)  AS registro_exec
        FROM
            eqtlinfo_prd.eqtl_ap.notas_servicos ns
            LEFT JOIN eqtlinfo_prd.eqtl_ap.visitas_notas vn
                ON vn.nota = ns.nota
            LEFT JOIN eqtlinfo_prd.eqtl_ap.info_gerais_notas ign
                ON ign.nota = ns.nota
            LEFT JOIN eqtlinfo_prd.eqtl_ap.tab_cadastro tc
                ON tc.instalacao = ns.instalacao
            LEFT JOIN eqtlinfo_prd.eqtl_ap.notas_fiscalizacao nf
                ON nf.nota = ns.nota
            LEFT JOIN eqtlinfo_prd.eqtl_ap.equipa_i_notas e
                ON ns.mandante = e.mandante
               AND ns.nota = e.nota
            LEFT JOIN SB_PERFORMANCE.eqtl_ap.tab_cod_irregularidade ir
                ON ir.irregularidade = nf.irregularidade
            LEFT JOIN eqtlinfo_prd.eqtl_ap.medidas_notas_servicos mns
                ON mns.nota = ns.nota
               AND mns.tipo_nota = ns.tipo_nota
               AND mns.data_encerramento_nota = ns.data_alteracao
               AND mns.grupo_medida = 'ALTEEQUI'
        WHERE
            ns.tipo_nota IN ( 'FS' )
            AND ns.data_encerramento >= TO_DATE('01/01/2023', 'DD/MM/YYYY') - 90
            AND ns.status_ccs IN ( 'FINL' )
            AND ns.codificacao NOT IN ( 'MDFC' )
        GROUP BY
            ns.tipo_nota,
            ns.nota,
            tc.latitude,
            tc.longitude,
            tc.bairro,
            ns.data_criacao,
            CASE
                WHEN mns.codigo_medida IN ( '0001', '0002' )
                     OR nf.irregularidade IN (
                        '109','115','154','155','175',
                        '188','201','204','214','215',
                        '221','307','308','311'
                     ) THEN 'P'
                WHEN aplicacao_ramal_conc = 'SIM' THEN 'P'
                ELSE 'I'
            END,
            CASE
                WHEN mns.codigo_medida IN ( '0001', '0002' )
                     OR nf.irregularidade IN (
                        '109','115','154','155','175',
                        '188','201','204','214','215',
                        '221','307','308','311'
                     ) THEN 1
                ELSE 0
            END,
            nf.aplicacao_ramal_conc,
            ns.data_encerramento,
            vn.nr_viatura,
            tc.regional,
            tc.municipio,
            tc.localidade,
            trunc(ns.instalacao,0),
            ns.grupo_codes,
            nf.irregularidade,
            ir.desc_irregularidade,
            nf.observacoes
    )
WHERE
   med_trocado = 1
   OR aplicacao_ramal_conc = 'SIM'