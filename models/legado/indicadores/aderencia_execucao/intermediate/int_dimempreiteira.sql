{{
    config(
        materialized='view',
        schema='silver',
        tags=['aderencia_execucao', 'intermediate']
    )
}}

WITH dimRegional AS (
    SELECT
        agrupv.ID AS idRegional,
        CASE WHEN agrupv.nome = 'CENTRO' AND AGRUP.NOME = 'EQTL - PI' THEN 'PICOS'
        WHEN agrupv.nome = 'SUL' AND AGRUP.NOME = 'EQTL - PI' THEN 'FLORIANO' ELSE AGRUPV.NOME END AS Regional,
        agrup.nome AS empresa,
        agrup.id AS idDistribuidora
    FROM EQTLINFO_RAW.SIPROG.AGRUPADOR_VALOR agrupv
    JOIN EQTLINFO_RAW.SIPROG.AGRUPADOR agrup 
        ON agrup.id = agrupv.agrupador
    WHERE agrup.nome LIKE '%EQTL%'
),
dimEmpreteira AS (
    SELECT 
        empr.id AS idEmpreteira,
        dimRegional.Regional AS Regional,
        dimRegional.empresa AS Empresa,
        empr.nome AS empreteira,
        empr.CONTRATO
    FROM EQTLINFO_RAW.SIPROG.EMPREITEIRA empr
    JOIN dimRegional 
        ON empr.REGIONAL = dimRegional.idRegional
    WHERE empr.ativo = 1
)
SELECT * FROM dimEmpreteira

