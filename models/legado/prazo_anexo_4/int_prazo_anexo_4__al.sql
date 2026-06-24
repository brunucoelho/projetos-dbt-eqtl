{{config(
    materialized='table'
)}}

with mds_ns AS (
    SELECT
    mns.NOTA,
    mns.MEDIDA,
    mns.TEXTO_MEDIDA,
    mns.STATUS_MEDIDA,
    mns.OBJETO,
    mns.GRUPO_MEDIDA,
    CAST(mns.DATA_DADOS AS TIMESTAMP_NTZ(9))               AS DATA_DADOS,
    CAST(mns.FIM_PROGRAMADO_MEDIDA     AS TIMESTAMP_NTZ(9)) AS FIM_PROGRAMADO_MEDIDA,
    CAST(mns.INICIO_PROGRAMADO_MEDIDA  AS TIMESTAMP_NTZ(9)) AS INICIO_PROGRAMADO_MEDIDA,
    CAST(mns.DATA_CONCLUSAO_MEDIDA     AS TIMESTAMP_NTZ(9)) AS DATA_CONCLUSAO_MEDIDA,
    FROM {{ source('eqtlinfo_prd_al', 'medidas_notas_servicos')}} mns
), 
medidas_ns as (
    SELECT DISTINCT * 
    FROM mds_ns mdns
    Where CAST(mdns.FIM_PROGRAMADO_MEDIDA AS TIMESTAMP_NTZ(9)) BETWEEN CAST(TO_TIMESTAMP_NTZ('01/01/2024 00:00:00','DD/MM/YYYY HH24:MI:SS') AS TIMESTAMP_NTZ(9)) AND DATEADD(MONTH,4,CAST(CURRENT_DATE() AS TIMESTAMP_NTZ(9)))
),
source_data as (
SELECT DISTINCT
'EQTL_AL' AS EMPRESA,
c.regional,
c.seccional,
c.municipio,
OS.INSTALACAO,
OS.CONTA_CONTRATO,
OS.NOTA,
MNS.medida,
MNS.OBJETO,
OS.TIPO_NOTA,
OS.TEXTO_BREVE,
OS.GRUPO_CODES,
CM.TEXTO_BREVE_CODIGO GRUPO_CODE_DESC,
os.CODIFICACAO,
MNS.grupo_medida,
TGM.TEXTO_BREVE_GRUPO_CODIGO, 
OS.AREA_ESTRUT_REGIONAL,
OS.STATUS_CCS,
OS.STATUSNTF2,
tsn.STATUS STATUS_NOTA,
os.DATA_NOTA,
-- FAZER CASE AQUI
CASE
    WHEN 
      CM.TEXTO_BREVE_CODIGO = 'Ligação Nova Normal'
       AND (TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Vistoria Ligação Nova') 
       --OR TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Informar dados de campo - Serv Rede'
       --OR (TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Execução da Ligação Nova' -- VERIFICAR AMOSTRAS
       --AND  SUBSTR(OS.CENTRO_TRABALHO,1,3) <> 'EXP'))
    THEN 'GESTAO SERV REDE'

    WHEN 
        CM.TEXTO_BREVE_CODIGO = 'Ligação Nova Reativação'
        AND (TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Vistoria Ligação Nova')
        --OR TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Informar dados de campo - Serv Rede'
        --OR TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Informar dados de campo - GERE'
        -- OR TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Execução da Ligação Nova') -- VERIFICAR AMOSTRAS
    THEN 'GESTAO SERV REDE'

/*     WHEN 
        CM.TEXTO_BREVE_CODIGO = 'Ligação Provisória Sem Medidor'
        AND (TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Vistoria de Ligação Provisória'
        OR TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Vistoria de Ligação Provisória')
    THEN 'GESTAO SERV REDE' */

    WHEN 
        CM.TEXTO_BREVE_CODIGO = 'Ligação Nova Normal - MT/AT'
        AND (TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Ligação da Instalação')
    THEN 'GESTAO SERV REDE'

    WHEN 
        CM.TEXTO_BREVE_CODIGO = 'LIGAÇÃO NOVA AT/BT'
        AND (TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Ligação da Instalação')
    THEN 'GESTAO SERV REDE'

    WHEN (
        (CM.TEXTO_BREVE_CODIGO = 'Religação Comum'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Execução do serviço'
             --AND GRUPO_CODES <> 'RELIGARI' -- PERDAS
             )

     OR (CM.TEXTO_BREVE_CODIGO = 'Religação Automática'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Execução do serviço'
             --AND GRUPO_CODES <> 'RELIGARI' -- PERDAS
             ) 

--     OR (CM.TEXTO_BREVE_CODIGO = 'Religação Judicial'
--             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Execução do serviço')

     OR (CM.TEXTO_BREVE_CODIGO = 'Religação por Corte Indevido'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Execução do serviço'
             --AND GRUPO_CODES <> 'RELIGARI' -- PERDAS
             )

/*     OR (CM.TEXTO_BREVE_CODIGO = 'Religação por Corte Indevido'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Execução do Serviço'
             AND  SUBSTR(OS.CENTRO_TRABALHO,1,3) <> 'REC'
             ) */

     OR (CM.TEXTO_BREVE_CODIGO = 'Mudança de Medidor de Local'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Vistoria P/ Mudança de Medidor de Local')

     OR (CM.TEXTO_BREVE_CODIGO = 'Troca de Padrão com Acréscimo de Carga'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Vistoria Troca de Padrão Com Acrescimo d')

     OR (CM.TEXTO_BREVE_CODIGO = 'Troca Padrão Sem Acréscimo de Carga'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Vist.Tro.de Pad.S/ Acresc. Carga')

     OR (CM.TEXTO_BREVE_CODIGO = 'Acesso à Microgeração Distribuída'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN ('Realizar Vistoria GD'))

     OR (CM.TEXTO_BREVE_CODIGO = 'Acesso à Minigeração Distribuída'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN ('Vistoria Aprovada'))

     OR (CM.TEXTO_BREVE_CODIGO = 'Deslocamento de ramal'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN ('Deslocamento de ramal',
                                                  'Deslocamento de Ramal'))

     OR (CM.TEXTO_BREVE_CODIGO = 'Desligamento - Com Leitura'
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Desligamento'
             AND  SUBSTR(OS.CENTRO_TRABALHO,1,3) <> 'GEC')

--     OR (CM.TEXTO_BREVE_CODIGO = 'Desligamento por Ligação Provisória'
--             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Desligamento')

--     OR (CM.TEXTO_BREVE_CODIGO = 'Desligamento Temporário'
--             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Desligamento')

--     OR (CM.TEXTO_BREVE_CODIGO = 'Inconformidade de Fornecimento'
--             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Inconformidade do Fornecimento')

--     OR (CM.TEXTO_BREVE_CODIGO = 'Inspeção Geral'
--             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Inpeção Geral')

--     OR (CM.TEXTO_BREVE_CODIGO = 'ConfIrmar Medidor em Serviço de Rede'
--             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Confirmar Medidor Instalado')

--     OR (CM.TEXTO_BREVE_CODIGO = 'Substituição de Ramal'
--             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Substituição de Ramal')

    )
    THEN 'GESTAO SERV REDE'

    WHEN (CM.TEXTO_BREVE_CODIGO = 'Religação Comum'
             AND GRUPO_CODES <> 'RELIGARI' -- PERDAS
             )
    THEN 'PERDAS'

    WHEN (CM.TEXTO_BREVE_CODIGO = 'Religação Automática'
             AND GRUPO_CODES <> 'RELIGARI' -- PERDAS
             ) 
    THEN 'PERDAS'

--     OR (CM.TEXTO_BREVE_CODIGO = 'Religação Judicial'
--             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Execução do serviço')

    WHEN (CM.TEXTO_BREVE_CODIGO = 'Religação por Corte Indevido'
             AND GRUPO_CODES <> 'RELIGARI' -- PERDAS
             )
    THEN 'PERDAS'

    WHEN (
        OS.tipo_nota = 'AV' -- PERDAS!
        AND os.CODIFICACAO = 'APCL'
        AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN 
            (
            'Análise da Avaliação Técnica'
            ))
    THEN 'PERDAS'

    WHEN (CM.TEXTO_BREVE_CODIGO = 'Desligamento Definitivo At' -- PERDAS!
             AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Realizar Desligamento')
    THEN 'PERDAS'

    WHEN CM.TEXTO_BREVE_CODIGO = 'Alteração de modalidade tarifária'  -- PERDAS!
     AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN (
         'Reprogramar medidor', 
         'Reprogramação de Medidor',
         'Avaliar reprogramação medidor'
         )
    THEN 'PERDAS'

/*    WHEN CM.TEXTO_BREVE_CODIGO = 'Alteração de modalidade tarifária' 
        AND TGM.TEXTO_BREVE_GRUPO_CODIGO NOT IN (
            'Reprogramar medidor', 'Reprogramação de Medidor',
            'Avaliar reprogramação medidor')
    THEN 'OUTROS'                           -- Relacionamento
*/

    WHEN CM.TEXTO_BREVE_CODIGO = 'Alteração para Tarifa Branca'
        AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN (
            'Vistoria Alteração para Tarifa Branca'
            )
    THEN 'GESTAO SERV REDE'                           -- Gestão de Serviços de Rede

/*    WHEN CM.TEXTO_BREVE_CODIGO = 'Alteração para Tarifa Branca'
        AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN (
            'Validação Cadastral', 'Validação em Campo')
    THEN 'OUTROS'                           -- Clientes
*/

    WHEN CM.TEXTO_BREVE_CODIGO = 'Alteração para Tarifa Convencional'
        AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN (
            'Vistoria de Alt. de Tarifa Convencional'
            )
    THEN 'GESTAO SERV REDE'


/*    WHEN CM.TEXTO_BREVE_CODIGO = 'Alteração para Tarifa Convencional'
        AND TGM.TEXTO_BREVE_GRUPO_CODIGO IN ('Validação Cadastral',
                                            'Validação em Campo')
    THEN 'OUTROS'
*/

    WHEN CM.TEXTO_BREVE_CODIGO = 'Alteração para Tarifa Convencional' -- PERDAS!
        AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Reprogramação de Medidor'
    THEN 'PERDAS'

/*    WHEN CM.TEXTO_BREVE_CODIGO = 'Alteração para Tarifa Convencional'
        AND TGM.TEXTO_BREVE_GRUPO_CODIGO = 'Tratamento de Rejeição'
    THEN 'OUTROS'
*/

    WHEN OS.TIPO_NOTA = 'OC'
        AND CM.TEXTO_BREVE_CODIGO <> 'Conexão Micro Geração'
        AND TGM.grupo_codigo = 'LEVANTOB'
    THEN 'GESTAO SERV REDE'

    WHEN OS.TIPO_NOTA = 'OC'
        AND CM.TEXTO_BREVE_CODIGO = 'Conexão Micro Geração'
        AND TGM.grupo_codigo = 'VISTCONX'
    THEN 'GESTAO SERV REDE'

    WHEN OS.TIPO_NOTA = 'OC'
        AND CM.TEXTO_BREVE_CODIGO = 'Orçamento Conexão Minigeração'
        AND TGM.grupo_codigo = 'INSTAMED'
    THEN 'PERDAS'

END RESPONSABILIDADE,

MNS.INICIO_PROGRAMADO_MEDIDA,
MNS.FIM_PROGRAMADO_MEDIDA,
MNS.DATA_CONCLUSAO_MEDIDA,
MNS.TEXTO_MEDIDA,
MNS.STATUS_MEDIDA,
OS.CENTRO_TRABALHO,
CASE
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) < 0 THEN 'FORA DO PRAZO'
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) > 0 THEN 'DENTRO DO PRAZO'
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) = 0 THEN 'DENTRO DO PRAZO'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) < 0 THEN 'FORA DO PRAZO'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) > 0 THEN 'DENTRO DO PRAZO'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) = 0 THEN 'DENTRO DO PRAZO'
 WHEN OS.TIPO_NOTA <> 'RL' AND MNS.DATA_CONCLUSAO_MEDIDA IS NULL THEN 'SEM DATA DE CONCLUSÃO'
 WHEN OS.TIPO_NOTA = 'RL' AND MNS.DATA_CONCLUSAO_MEDIDA IS NULL THEN 'SEM DATA DE CONCLUSÃO'
 WHEN OS.STATUS_CCS = 'ERRO' THEN 'STATUS ERRO'
 END status_prazo,
CASE
    -- ARRUMAR, NÃO PODE SER IGUAL, TEM QUE SER NA MESMA DATA SE FOR EM DATA MENOR ANTECIPADO E NADA DATA DEPOIS ATRASADO
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) < 0 AND (MNS.STATUS_MEDIDA = 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NOT NULL) THEN 'Executado Fora do Prazo'
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) > 0 AND (MNS.STATUS_MEDIDA = 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NOT NULL) THEN 'Executado Antecipado'
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) = 0 AND (MNS.STATUS_MEDIDA = 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NOT NULL) THEN 'Executado Na Data'
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, OS.DATA_DADOS, MNS.FIM_PROGRAMADO_MEDIDA) > 0 AND (MNS.STATUS_MEDIDA <> 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NULL) THEN 'Aberta no Prazo'
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, OS.DATA_DADOS, MNS.FIM_PROGRAMADO_MEDIDA) < 0 AND (MNS.STATUS_MEDIDA <> 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NULL) THEN 'Aberta Fora do Prazo'
 WHEN OS.TIPO_NOTA = 'RL' AND DATEDIFF(HOUR, OS.DATA_DADOS, MNS.FIM_PROGRAMADO_MEDIDA) = 0 AND (MNS.STATUS_MEDIDA <> 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NULL) THEN 'Aberta No Dia'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) < 0 AND (MNS.STATUS_MEDIDA = 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NOT NULL) THEN 'Executado Fora do Prazo'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) > 0 AND (MNS.STATUS_MEDIDA = 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NOT NULL) THEN 'Executado Antecipado'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, MNS.DATA_CONCLUSAO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA) = 0 AND (MNS.STATUS_MEDIDA = 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NOT NULL) THEN 'Executado Na Data'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, OS.DATA_DADOS, MNS.FIM_PROGRAMADO_MEDIDA) > 0 AND (MNS.STATUS_MEDIDA <> 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NULL) THEN 'Aberta no Prazo'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, OS.DATA_DADOS, MNS.FIM_PROGRAMADO_MEDIDA) < 0 AND (MNS.STATUS_MEDIDA <> 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NULL) THEN 'Aberta Fora do Prazo'
 WHEN OS.TIPO_NOTA <> 'RL' AND DATEDIFF(DAY, OS.DATA_DADOS, MNS.FIM_PROGRAMADO_MEDIDA) = 0 AND (MNS.STATUS_MEDIDA <> 'MEDE' OR MNS.DATA_CONCLUSAO_MEDIDA IS NULL) THEN 'Aberta No Dia'
 WHEN OS.TIPO_NOTA = 'RL' AND MNS.DATA_CONCLUSAO_MEDIDA IS NULL AND MNS.STATUS_MEDIDA = 'MEDE' THEN 'Executado Sem Data de Conlusão'
 WHEN OS.TIPO_NOTA <> 'RL' AND MNS.DATA_CONCLUSAO_MEDIDA IS NULL AND MNS.STATUS_MEDIDA = 'MEDE' THEN 'Executado Sem Data de Conlusão'
END status_prazo_medida,
CASE 
    WHEN OS.TIPO_NOTA = 'LN' THEN 'D'
    WHEN OS.TIPO_NOTA = 'RL' THEN 'H'
    WHEN OS.TIPO_NOTA = 'MM' THEN 'D'
    WHEN OS.TIPO_NOTA = 'TP' THEN 'D'
    WHEN OS.TIPO_NOTA = 'MG' THEN 'D'
    WHEN OS.TIPO_NOTA = 'DR' THEN 'D'
    WHEN OS.TIPO_NOTA = 'DS' THEN 'D'
    WHEN OS.TIPO_NOTA = 'NT' THEN 'D'
    WHEN OS.TIPO_NOTA = 'IS' THEN 'D'
    WHEN OS.TIPO_NOTA = 'MT' THEN 'D'
    ELSE 'D'
END TIPO_PRAZO,
CASE
    WHEN OS.TIPO_NOTA = 'RL' AND MNS.DATA_CONCLUSAO_MEDIDA IS NOT NULL THEN
        DATEDIFF(HOUR, MNS.DATA_CONCLUSAO_MEDIDA, MNS.INICIO_PROGRAMADO_MEDIDA)
    WHEN OS.TIPO_NOTA <> 'RL' AND MNS.DATA_CONCLUSAO_MEDIDA IS NOT NULL THEN
        DATEDIFF(DAY, MNS.DATA_CONCLUSAO_MEDIDA, MNS.INICIO_PROGRAMADO_MEDIDA)
    WHEN OS.TIPO_NOTA = 'RL' AND MNS.DATA_CONCLUSAO_MEDIDA IS NULL THEN
        DATEDIFF(HOUR, CAST(CURRENT_DATE() AS TIMESTAMP_NTZ(9)), MNS.FIM_PROGRAMADO_MEDIDA)
    WHEN OS.TIPO_NOTA <> 'RL' AND MNS.DATA_CONCLUSAO_MEDIDA IS NULL THEN
        DATEDIFF(DAY, CAST(CURRENT_DATE() AS TIMESTAMP_NTZ(9)), MNS.FIM_PROGRAMADO_MEDIDA)
    ELSE
        0
END PRAZO_VERIFICADO,
CASE
    WHEN OS.TIPO_NOTA = 'RL' THEN
        DATEDIFF(HOUR, MNS.INICIO_PROGRAMADO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA)
    WHEN OS.TIPO_NOTA <> 'RL' THEN
        DATEDIFF(DAY, MNS.INICIO_PROGRAMADO_MEDIDA, MNS.FIM_PROGRAMADO_MEDIDA)
    ELSE
        0
END PRAZO_REGULADO,
 SUBSTR(MNS.TEXTO_MEDIDA,1,3) Equipe,
 SUBSTR(OS.CENTRO_TRABALHO,1,3) CENTRO_TRAB_RESPONS_NOTA,
 OS.DATA_DADOS Atualiz_NS,
 --B.DATA_DADOS Atualiz_Visitas,
 MNS.DATA_DADOS Atualiz_Medid,
 C.DATA_DADOS Atualiz_TabCad,
 md5(
      concat_ws('||',
        COALESCE(c.regional,'0'),
        COALESCE(c.seccional,'0'),
        COALESCE(c.municipio,'0'),
        COALESCE(OS.NOTA,'0'),
        COALESCE(TO_CHAR(MNS.INICIO_PROGRAMADO_MEDIDA,'YYYY-MM-DD HH24:MI:SS'),'0'),
        COALESCE(TGM.TEXTO_BREVE_GRUPO_CODIGO,'0'),
        COALESCE(MNS.OBJETO,'0'),
        COALESCE(os.CODIFICACAO,'0'),
        COALESCE(os.TIPO_NOTA,'0'),
        COALESCE(TO_CHAR(MNS.DATA_CONCLUSAO_MEDIDA,'YYYY-MM-DD HH24:MI:SS'),'0'),
        COALESCE(tsn.STATUS,'0'),
        COALESCE(MNS.TEXTO_MEDIDA,'0'),
        COALESCE(OS.CENTRO_TRABALHO,'0'),
        COALESCE(TO_CHAR(os.DATA_NOTA,'YYYY-MM-DD HH24:MI:SS'),'0'),
        COALESCE(MNS.STATUS_MEDIDA,'0')
      )
    ) AS record_hash,
    {{ timestamp_now() }} data_dados
--OS.NOTA_VINCULADA
	FROM {{ source('eqtlinfo_prd_al', 'notas_servicos')}} OS
    LEFT JOIN medidas_ns mns ON MNS.NOTA = OS.NOTA
    LEFT JOIN {{ source('eqtlinfo_prd_al', 'tab_cadastro')}} c on os.instalacao = c.instalacao -- AND os.CONTA_CONTRATO = c.CONTA_CONTRATO 
    LEFT JOIN {{ source('eqtlinfo_prd_al', 'tab_grpcodes_medidas')}} tgm ON MNS.GRUPO_MEDIDA = tgm.GRUPO_CODIGO
    LEFT JOIN {{ source('eqtlinfo_prd_al', 'tab_status_notas')}} tsn ON OS.STATUS_CCS = TSN.STATUS_CCS AND OS.STATUSNTF2 = TSN.CODIGO_CCS
    LEFT JOIN {{ source('eqtlinfo_prd_al', 'tab_codes_medidas')}} cm ON os.GRUPO_CODES = cm.GRUPO_CODIGO AND os.CODIFICACAO = cm.CODIGO AND os.TIPO_CATALOGO = cm.CATALOGO
    WHERE 21 = 21
AND CAST(MNS.FIM_PROGRAMADO_MEDIDA AS TIMESTAMP_NTZ(9)) BETWEEN CAST(TO_TIMESTAMP_NTZ('01/01/2024 00:00:00','DD/MM/YYYY HH24:MI:SS') AS TIMESTAMP_NTZ(9)) AND DATEADD(MONTH,4,CAST(CURRENT_DATE() AS TIMESTAMP_NTZ(9)))
AND os.tipo_nota IN ('LN','RL','MM','TP','MG','DR','DS','NT','IS','MT','AV','OC') --('LN','RL','MM','TP','MG','DR','DS','NT','IS')
AND OS.STATUS_CCS NOT IN ('CANC','RECE')
AND SUBSTR(mns.TEXTO_MEDIDA,1,3) NOT IN ('EXP','GEC','OPS','CANC')

)

SELECT DISTINCT * FROM source_data