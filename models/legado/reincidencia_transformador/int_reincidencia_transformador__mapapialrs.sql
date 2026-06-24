{{config(
    materialized='table'
)}}

WITH BASE AS (
    SELECT 
        'EQTL PA' AS EMPRESA,
        CURRENT_TIMESTAMP AS DATA_CARGA,
        gdf.REGIONAL,
        gdf.SECCIONAL,
        gdf.DATA,
        gdf.DATA_CONCLUSAO,
        gdf.NATUREZA,
        gdf.perimetro,
        gdf.CAUSA,
        TO_CHAR(gdf.OCO_NUMERO) AS OCO_NUMERO,
        case 
            when
                length(REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')) >= 8 
                then 'INC '||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
            else gdf.ANO||'-'||gdf.MES||'-'||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
        end AS OCORRENCIA,
        gdf.ABRANGENCIA,
        gdf.PDF,
        gdf.EQUIPE AS PRX_DESCRICAO,
        gdf.TIPO_EQP,
        gdf.CHI_CLIENTE AS CHI,
        gdf.CLI_CLIENTE AS CLIE,
        gdf.PROCEDENCIA
    FROM {{ ref('stg_sb_operacao_gestao_dec_fec_pa') }} gdf
    WHERE ABRANGENCIA = 'TF'
      AND PROCEDENCIA IN ('P')
      AND NATUREZA NOT IN ('PROGRAMADA')
    
   UNION ALL
    SELECT 
        'EQTL PI', CURRENT_TIMESTAMP, REGIONAL, SECCIONAL, DATA, DATA_CONCLUSAO, NATUREZA, gdf.perimetro,CAUSA,
        TO_CHAR(OCO_NUMERO),
        case 
            when
                length(REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')) >= 8 
                then 'INC '||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
            else gdf.ANO||'-'||gdf.MES||'-'||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
        end AS OCORRENCIA,
         ABRANGENCIA, PDF, EQUIPE, TIPO_EQP, CHI_CLIENTE, CLI_CLIENTE, PROCEDENCIA
    FROM {{ ref('stg_sb_operacao_gestao_dec_fec_pi') }} gdf
    WHERE ABRANGENCIA = 'TF'
      AND PROCEDENCIA IN ('P')
      AND NATUREZA NOT IN ('PROGRAMADA')
 
    UNION ALL
    SELECT 
        'EQTL AL', CURRENT_TIMESTAMP, REGIONAL, SECCIONAL, DATA, DATA_CONCLUSAO, NATUREZA, gdf.perimetro,CAUSA,
        TO_CHAR(OCO_NUMERO),
        case 
            when
                length(REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')) >= 8 
                then 'INC '||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
            else gdf.ANO||'-'||gdf.MES||'-'||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
        end AS OCORRENCIA,
        ABRANGENCIA, PDF, EQUIPE, TIPO_EQP, CHI_CLIENTE, CLI_CLIENTE, PROCEDENCIA
    FROM {{ ref('stg_sb_operacao_gestao_dec_fec_al') }} gdf
    WHERE ABRANGENCIA = 'TF'
      AND PROCEDENCIA IN ('P')
      AND NATUREZA NOT IN ('PROGRAMADA') 
    UNION ALL
    SELECT 
        'EQTL AP', CURRENT_TIMESTAMP, REGIONAL, SECCIONAL, DATA, DATA_CONCLUSAO, NATUREZA, gdf.perimetro,CAUSA,
        TO_CHAR(OCO_NUMERO),
        case 
            when
                length(REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')) >= 8 
                then 'INC '||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
            else gdf.ANO||'-'||gdf.MES||'-'||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
        end AS OCORRENCIA,
        ABRANGENCIA, PDF, EQUIPE, TIPO_EQP, CHI_CLIENTE, CLI_CLIENTE, PROCEDENCIA
    FROM {{ ref('stg_sb_operacao_gestao_dec_fec_ap') }} gdf
    WHERE ABRANGENCIA = 'TF'
      AND PROCEDENCIA IN ('P')
      AND NATUREZA NOT IN ('PROGRAMADA')
 
    UNION ALL
    SELECT 
   'EQTL RS', CURRENT_TIMESTAMP, REGIONAL, 
        CASE WHEN BASE IN ('ARROIO DOS RATOS','GUAIBA','BUTIA','SAO JERONIMO','PANTANO GRANDE') 
        AND GDF.DATA <= TO_DATE('31-07-2024', 'DD-MM-YYYY')THEN 'Carbonífera'
        ELSE SECCIONAL
        END SECCIONAL, GDF.DATA, DATA_CONCLUSAO, NATUREZA, gdf.perimetro,CAUSA,
        TO_CHAR(OCO_NUMERO),
        case 
            when
                length(REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')) >= 8 
                then 'INC '||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
            else gdf.ANO||'-'||gdf.MES||'-'||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
        end AS OCORRENCIA,
        ABRANGENCIA, PDF, EQUIPE, TIPO_EQP, CHI_CLIENTE, CLI_CLIENTE, PROCEDENCIA
FROM {{ ref('stg_sb_operacao_gestao_dec_fec_rs') }} GDF
    WHERE ABRANGENCIA = 'TF'
      AND PROCEDENCIA IN ('P')
      AND NATUREZA NOT IN ('PROGRAMADA')
 
    UNION ALL
    SELECT 
        'EQTL MA', CURRENT_TIMESTAMP, REGIONAL, SECCIONAL, DATA, DATA_CONCLUSAO, NATUREZA, gdf.perimetro,CAUSA,
        TO_CHAR(OCO_NUMERO),
        case 
            when
                length(REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')) >= 8 
                then 'INC '||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
            else gdf.ANO||'-'||gdf.MES||'-'||REGEXP_REPLACE(TO_CHAR(gdf.OCO_NUMERO),'\\.0+$', '')
        end AS OCORRENCIA,
        ABRANGENCIA, PDF, EQUIPE, TIPO_EQP, CHI_CLIENTE, CLI_CLIENTE, PROCEDENCIA
    FROM {{ ref('stg_sb_operacao_gestao_dec_fec_ma') }} gdf
    WHERE ABRANGENCIA = 'TF'
      AND PROCEDENCIA IN ('P')
      AND NATUREZA NOT IN ('PROGRAMADA')
      /*UNION ALL 
      
      SELECT 
        'EQTL GO', CURRENT_TIMESTAMP, REGIONAL, SECCIONAL, DATA, DATA_CONCLUSAO, NATUREZA, gdf.perimetro,CAUSA,
        TO_CHAR(OCO_NUMERO), ABRANGENCIA, PDF, EQUIPE, TIPO_EQP, CHI_CLIENTE, CLI_CLIENTE, PROCEDENCIA
    FROM SB_OPERACAO.OPERACAO_GO.GESTAO_DEC_FEC_GO gdf
    WHERE ABRANGENCIA = 'TF'
      AND PROCEDENCIA IN ('P')
      AND NATUREZA NOT IN ('PROGRAMADA')*/
      
      
),
 
REINCIDENCIA_90 AS (
    SELECT
        EMPRESA,
        PDF,
        DATA,
        1 AS REINCIDENTE_90
    FROM BASE
    WHERE NATUREZA NOT IN ('PROGRAMADO', 'Z-PROGRAMADO','PROGRAMADA')
),
 
OCORRENCIA_ANTERIOR AS (
    SELECT
        b1.EMPRESA,
        b1.PDF,
        b2.DATA AS DATA_ATUAL,
        b1.OCORRENCIA AS OCORRENCIA_ANTERIOR,
        b1.PRX_DESCRICAO AS EQUIPE_ANTERIOR,
        b1.CAUSA AS CAUSA_ANTERIOR,
        ROW_NUMBER() OVER (
            PARTITION BY b1.EMPRESA, b1.PDF, b2.DATA
            ORDER BY b1.DATA DESC
        ) AS rn
    FROM BASE b1
    JOIN BASE b2
        ON b1.EMPRESA = b2.EMPRESA
       AND b1.PDF = b2.PDF
       AND b1.DATA < b2.DATA
),
 
PRE_AGREGACAO AS (
    SELECT
        b.EMPRESA,
        b.DATA_CARGA,
        b.REGIONAL,
        b.SECCIONAL,
        b.DATA,
        b.DATA_CONCLUSAO,
        b.NATUREZA,
        b.perimetro,
        b.CAUSA,
        b.OCORRENCIA,
        b.OCO_NUMERO,
        b.ABRANGENCIA,
        b.PDF,
        b.PRX_DESCRICAO,
        DECODE(b.TIPO_EQP, 'CH FUSÍVEL', 'FUSÍVEL', 'TRAFO CEMAR', 'TRANSFORMADOR', b.TIPO_EQP) AS TIPO_EQP,
        b.CHI,
        b.CLIE,
        CASE
            WHEN b.CAUSA ILIKE ANY('%DESLIGAMENTO PROGRAMADO%','%PTP%')
                 AND NOT EXISTS (
                     SELECT 1
                     FROM BASE bx
                     WHERE bx.EMPRESA = b.EMPRESA
                       AND bx.PDF = b.PDF
                       AND bx.DATA < b.DATA
                       AND bx.DATA >= DATEADD(DAY, -90, b.DATA)
                       AND bx.CAUSA ILIKE ANY('%DESLIGAMENTO PROGRAMADO%','%PTP%')
                 )
            THEN 'N'
            WHEN r.REINCIDENTE_90 IS NOT NULL THEN 'S'
            ELSE 'N'
        END AS REINCIDENTE_90_DIAS,
        r.REINCIDENTE_90,
        oa.OCORRENCIA_ANTERIOR,
        oa.EQUIPE_ANTERIOR,
        oa.CAUSA_ANTERIOR
    FROM BASE b
    LEFT JOIN REINCIDENCIA_90 r
        ON r.PDF = b.PDF
       AND r.EMPRESA = b.EMPRESA
       AND r.DATA < b.DATA
       AND r.DATA >= DATEADD(DAY, -90, b.DATA)
    LEFT JOIN OCORRENCIA_ANTERIOR oa
        ON oa.EMPRESA = b.EMPRESA
       AND oa.PDF = b.PDF
       AND oa.DATA_ATUAL = b.DATA
       AND oa.rn = 1
    WHERE
        b.PROCEDENCIA = 'P'
        AND b.TIPO_EQP in ('TRAFO CEMAR','TRANSFORMADOR','OUTRO','CHAVE FUSIVEL','CHAVE COMPOSTA URBANO','CHAVE COMPOSTA RURAL','INSTALACÃO TRANSFORMADORA COMPANHIA')
        AND b.ABRANGENCIA = 'TF'
        AND b.NATUREZA NOT IN ('PROGRAMADO', 'Z-PROGRAMADO','PROGRAMADA')
        AND b.DATA >= TO_DATE('01-01-2023', 'DD-MM-YYYY')
),
 
DADOS_FINAIS AS (
    SELECT
        EMPRESA,
        DATA_CARGA,
        REGIONAL,
        SECCIONAL,
        DATA,
        DATA_CONCLUSAO,
        NATUREZA,
        perimetro,
        CAUSA,
        OCORRENCIA,
        OCO_NUMERO,
        ABRANGENCIA,
        PDF,
        PRX_DESCRICAO,
        TIPO_EQP,
        CHI,
        CLIE,
        REINCIDENTE_90_DIAS,
        OCORRENCIA_ANTERIOR,
        EQUIPE_ANTERIOR,
        CAUSA_ANTERIOR,
        SUM(COALESCE(REINCIDENTE_90, 0)) AS N_REINC
    FROM PRE_AGREGACAO
   -- WHERE PDF = '2763664'
    GROUP BY
        EMPRESA,
        DATA_CARGA,
        REGIONAL,
        SECCIONAL,
        DATA,
        DATA_CONCLUSAO,
        NATUREZA,
        perimetro,
        CAUSA,
        OCORRENCIA,
        OCO_NUMERO,
        ABRANGENCIA,
        PDF,
        PRX_DESCRICAO,
        TIPO_EQP,
        CHI,
        CLIE,
        REINCIDENTE_90_DIAS,
        OCORRENCIA_ANTERIOR,
        EQUIPE_ANTERIOR,
        CAUSA_ANTERIOR
) 
SELECT * FROM DADOS_FINAIS