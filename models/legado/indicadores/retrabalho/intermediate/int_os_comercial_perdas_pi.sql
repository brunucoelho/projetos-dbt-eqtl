{{ config(materialized='table') }}

SELECT
    *
FROM
    (
        SELECT
        'EQTL PI' AS EMPRESA,
            ns.tipo_nota                   ostipo,
            current_timestamp data_carga,
            ns.nota                        os_oper,
            to_char(ns.data_criacao, 'YYYY')
            || '-'
            || to_char(ns.data_criacao, 'MM')
            || '/'
            || ns.nota                     os,
            tc.latitude,
            tc.longitude,
            tc.bairro,
            'COMERCIAL' AS ABRANGENCIA,
            null AS COMPONENTE_DANIFICADO,
            null AS TB_DEFEITO_ID,

                 --NS.GRUPO_CODES,
                 --NS.CODIFICACAO AS CODE,
                 --NS.MES_COMPETENCIA AS CMPT_CRIACAO,
                 --NS.CRIADO_POR,
            ns.data_criacao                AS data_origem,
                -- TO_CHAR (NS.DATA_ALTERACAO, 'DD/MM/YYYY') AS DATA_BAIXA,
                 --TO_CHAR (NS.DATA_ALTERACAO, 'MM.YYYY') AS CMPT_BAIXA,
                        
            CASE
                WHEN mns.codigo_medida IN ( '0001', '0002' )
                     OR nf.irregularidade IN ( '109', '115',
                                               '154',
                                               '155',
                                               '175',
                                               '188',
                                               '201',
                                               '204',
                                               '214',
                                               '215',
                                               '221',
                                               '307',
                                               '308',
                                               '311' ) THEN
                    'P'
                WHEN aplicacao_ramal_conc = 'SIM' THEN
                    'P'
                ELSE
                    'I'
            END                            tipo,
           CASE
                WHEN mns.codigo_medida IN ( '0001', '0002' )
                     OR nf.irregularidade IN ( '109', '115',
                                               '154',
                                               '155',
                                               '175',
                                               '188',
                                               '201',
                                               '204',
                                               '214',
                                               '215',
                                               '221',
                                               '307',
                                               '308',
                                               '311' ) THEN
                    1
                ELSE
                    0
            END                            med_trocado,
            nf.aplicacao_ramal_conc,
                 --NS.CATEGORIA_TARIFA,
                 --NS.ALTERADO_POR,
                 --NS.SISTEMA_DIRECIONADO,
                 --NS.CENTRO_CENTRAB,
                 --NS.CENTRO_TRABALHO,
                 --NS.STATUS_CCS AS STATUS_NOTA,
            ns.data_encerramento           AS oco_data_conclusao,
                
                 --TO_CHAR (VN.DATA_FINAL_SERVICO, 'MM.YYYY') AS CMPT_SERVICO,
                 --TRUNC(NS.DATA_ALTERACAO - VN.DATA_FINAL_SERVICO,0) AS TMB,
                -- ROUND (NS.DATA_ALTERACAO - VN.DATA_FINAL_SERVICO) AS TMB,
                /* CASE
                    WHEN ROUND (NS.DATA_ALTERACAO - VN.DATA_FINAL_SERVICO) > 10
                    THEN
                       'FORA DO PRAZO'
                    ELSE
                       'DENTRO DO PRAZO'
                 END
                    TMB_PRAZO,*/
                 --VN.NR_VIATURA AS PREFIXO,
            vn.nr_viatura as prefixo,
                /*-- VN.MATRICULA_EXECUTOR AS MAT_ELET_1,
                 --VN.NOME_EXECUTOR AS ELETRICISTA_1,
                -- VN.MATRICULA_EXECUTOR2 AS MAT_ELET_2,
                 --VN.NOME_EXECUTOR2 AS ELETRICISTA_2,
                 --VN.TOI,
                -- IGN.TOI_ASSINADO,
                 CASE
                    WHEN IGN.TOI_ASSINADO LIKE 'S%' THEN 'SIM'
                    WHEN IGN.TOI_ASSINADO LIKE 'N%' THEN 'NAO'
                    ELSE 'ERRO'
                 END
                    TOI_ENTREGUE,
                 TC.STATUS_COMERCIAL AS STATUS_IN,
                 TC.GRUPO_TENSAO,
                 NS.UNIDADE_LEITURA AS UL_SERVICO,
                 TC.UNIDADE_LEITURA AS UL_ATUAL,
                 (SELECT NS1.UNIDADE_LEITURA
                    FROM cepisa.NOTAS_SERVICOS NS1
                   WHERE NS1.CONTA_CONTRATO = NS.CONTA_CONTRATO
                         AND NS1.TIPO_NOTA = 'LN'
                         AND (NS1.DATA_ALTERACAO = NS.DATA_ALTERACAO
                              OR NS1.DATA_ALTERACAO + 1 = NS.DATA_ALTERACAO))
                    AS UL_CRM,
                 --TC.FASE,
                 --.MICRO_GERADOR,
                 --TC.INST_MED_FISCAL,*/
            tc.regional,
                 --TC.DISTRITAL,
            tc.municipio,
            TC.LOCALIDADE,
                 --TC.BAIRRO,
                 --TC.LOCAL_INSTALACAO_MEDIDOR AS LOCAL_MEDICAO,
            trunc(ns.instalacao,0)        uc,
                 --LTRIM (TC.MEDIDOR, '0') AS MEDIDOR_ATUAL,
                --NF.MEDIDOR AS MEDIDOR_ENCONTRADO,
                NS.GRUPO_CODES AS ossubtipo,
            nf.irregularidade              AS COD_CONCLUSAO,
            ir.desc_irregularidade         tipo_conclusao,
            2000 AS COD_SUBCAUSA,
            'COMERCIAL' AS SUBCAUSA,
            
                 --NF.LEITURA_ATIVA AS LEITURA_RET, --LEITURA DO MEDIDOR RETIRADO
                 --NF.DATA_ALTERACAO AS DTA_TROCA_MED,        --TROCA DO MEDIDOR
            substr(nf.observacoes,0,250)    AS registro_exec
        FROM
            {{ source('EQTL_PI', 'notas_servicos') }} ns
            LEFT JOIN {{ source('EQTL_PI', 'visitas_notas') }}   vn ON vn.nota = ns.nota
            LEFT JOIN {{ source('EQTL_PI', 'info_gerais_notas') }}         ign ON ign.nota = ns.nota
            LEFT JOIN {{ source('EQTL_PI', 'tab_cadastro') }}         tc ON tc.instalacao = ns.instalacao
            LEFT JOIN {{ source('EQTL_PI', 'notas_fiscalizacao') }}    nf ON nf.nota = ns.nota
            LEFT JOIN {{ source('EQTL_PI', 'equipa_i_notas') }}           e ON ns.mandante = e.mandante
                                               AND ns.nota = e.nota
            LEFT JOIN  {{ source('EQTL_PI_PERFORMANCE', 'tab_cod_irregularidade_pi') }}    ir ON ir.irregularidade = try_to_number(nf.irregularidade)
            LEFT JOIN  {{ source('EQTL_PI', 'medidas_notas_servicos') }}    mns ON mns.nota = ns.nota
                                                         AND mns.tipo_nota = ns.tipo_nota
                                                         AND mns.data_encerramento_nota = ns.data_alteracao
                                                         AND mns.grupo_medida = 'ALTEEQUI'
        WHERE
            ns.tipo_nota IN ( 'FS' )
            AND  
--AND TO_CHAR (VN.DATA_FINAL_SERVICO, 'MM.YYYY')
             --ns.mes_competencia = '202401'
--and TRUNC(NS.instalacao,0) = '16571541'
--ns.data_encerramento >= TO_DATE('01-01-2023','DD-MM-YYYY')-90
--{% if is_incremental() %}
        --ns.data_encerramento >= (SELECT MAX(ns.data_encerramento) FROM {{ this }})
    --{% else %}
        ns.data_encerramento >= TO_DATE('01/01/2023', 'DD/MM/YYYY') - 90
    --{% endif %}
--ns.data_encerramento>= sysdate - 90
/*ns.data_encerramento BETWEEN TO_DATE (
		'01/08/2024',
		'DD/MM/YY')
 AND TO_DATE (
		'31/08/2024',
		'DD/MM/YY')*/
		
            AND ns.status_ccs IN ( 'FINL' )
		--AND NS.STATUS_CCS NOT IN ('ATIV', 'CANC')
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
                         OR nf.irregularidade IN ( '109', '115',
                                                   '154',
                                                   '155',
                                                   '175',
                                                   '188',
                                                   '201',
                                                   '204',
                                                   '214',
                                                   '215',
                                                   '221',
                                                   '307',
                                                   '308',
                                                   '311' ) THEN
                        'P'
                    WHEN aplicacao_ramal_conc = 'SIM' THEN
                        'P'
                    ELSE
                        'I'
            END,
            CASE
                WHEN mns.codigo_medida IN ( '0001', '0002' )
                     OR nf.irregularidade IN ( '109', '115', '154', '155', '175',
                                               '188', '201', '204', '214', '215',
                                               '221', '307', '308', '311' ) THEN
                        1
                ELSE
                    0
            END,
            nf.aplicacao_ramal_conc,
            ns.data_encerramento,
            --vn.data_final_servico,
            vn.nr_viatura,
            tc.regional,
            tc.municipio,
            TC.LOCALIDADE,
            trunc(ns.instalacao,0),
            NS.GRUPO_CODES,
            nf.irregularidade,
            ir.desc_irregularidade,
            nf.observacoes
    )
WHERE
   med_trocado = 1
    OR aplicacao_ramal_conc = 'SIM'