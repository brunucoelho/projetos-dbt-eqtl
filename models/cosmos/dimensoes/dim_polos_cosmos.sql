{{
  config(
    materialized='table',
    alias='dim_polos_cosmos',
    schema='silver',
    tags=['dimension', 'polos', 'cosmos']
  )
}}

SELECT 
    polo_id,
    UPPER(TRANSLATE(
        REPLACE(pol_nome, '_', ' '),
        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇÑáàãâäéèêëíìîïóòõôöúùûüçñ',
        'AAAAAEEEEIIIIOOOOOUUUUCNaaaaaeeeeiiiiooooouuuucn'
    )) as pol_nome,
    regional_id,
    CURRENT_TIMESTAMP as dt_atualizacao
FROM (
    VALUES
        -- Polos de teste (sem correspondência)
        (286, 'Polo teste 1', 44),
        (288, 'Polo teste 3', 44),
        (289, 'Polo teste 4', 47),
        (290, 'Polo teste 5', 47),
        (292, 'Teste Luigi', 44),
        (294, 'Polo teste 55', 27),
        (287, 'Polo teste 2', 44),
        (291, 'Polo teste Maranhão', 44),
        (293, 'Polo Luigi', 44),
        
        -- Polos mapeados
        (257, 'ÁGUAS LINDAS', 29),
        (238, 'CAMPOS BELOS', 41),
        (252, 'RIO VERDE', 31),
        (207, 'VIANA', 47),
        (208, 'SÃO_RAIMUNDO_NONATO', 34),
        (209, 'MARABA', 38),
        (210, 'OIAPOQUE', 27),
        (211, 'ALTAMIRA', 39),
        (212, 'PINHEIRO', 47),
        (213, 'METROPOLITANA', 48),  -- Alagoas Norte
        (214, 'TIMON', 45),
        (215, 'ABAETETUBA', 42),
        (216, 'PARAGOMINAS', 42),
        (217, 'GRAJAÚ', 28),
        (218, 'CAMPO_MAIOR', 40),
        (219, 'GOIÁS', 43),
        (220, 'PARNAÍBA', 22),
        (221, 'FORMOSA', 41),
        (222, 'SERTÃO', 46),
        (223, 'CENTRO', 46),
        (224, 'IMPERATRIZ', 28),
        (225, 'JARAGUÁ', 21),
        (226, 'SÃO_LUIS', 37),
        (227, 'CATALÃO', 33),
        (228, 'PICOS', 34),
        (229, 'METROPOLITANA', 27),  -- Amapá
        (230, 'TERESINA', 40),
        (231, 'BALSAS', 28),
        (232, 'CARBONÍFERA', 26),
        (233, 'IPORÁ', 36),
        (234, 'CASTANHAL', 42),
        (235, 'REDENÇÃO', 38),
        (236, 'METROPOLITANA', 30),  -- Goiânia
        (237, 'PARAUAPEBAS', 38),
        (239, 'FLORIANO', 34),
        (240, 'FIRMINÓPOLIS', 43),
        (241, 'SÃO_PEDRO', 40),
        (242, 'GOIÂNIA', 24),
        (243, 'QUIRINÓPOLIS', 31),
        (244, 'METROPOLITANA', 26),  -- Rio Grande do Sul
        (245, 'TUCURUÍ', 38),
        (246, 'PORTO_GRANDE', 27),
        (247, 'ITAPECURU', 44),
        (248, 'GOV._N._FREIRE', 47),
        (249, 'CAXIAS', 45),
        (250, 'CAPANEMA', 42),
        (251, 'SÃO_JOÃO_DOS_PATOS', 45),
        (253, 'ROSARIO', 37),
        (254, 'PIRIPIRI', 22),
        (255, 'BARREIRINHAS', 37),
        (256, 'LUZIÂNIA', 29),
        (258, 'OEIRAS', 34),
        (259, 'LITORAL_NORTE', 26),
        (260, 'CANAÃ_DOS_CARAJÁS', 38),
        (261, 'TARTARUGALZINHO', 27),
        (262, 'SANTARÉM', 35),
        (263, 'CAMPANHA', 32),
        (264, 'BOM_JESUS', 34),
        (265, 'UNIÃO', 40),
        (266, 'ACAILANDIA', 28),
        (267, 'PEDREIRAS', 44),
        (268, 'PRESIDENTE_DUTRA', 44),
        (269, 'CENTRO_SUL', 32),
        (270, 'SUL', 32),
        (271, 'SANTA_INES', 44),
        (272, 'SOURE', 23),
        (273, 'BACABAL', 44),
        (274, 'JATAÍ', 36),
        (275, 'JARI', 27),
        (276, 'BELÉM', 23),
        (277, 'ANÁPOLIS', 21),
        (278, 'MORRINHOS', 33),
        (279, 'ITAITUBA', 35),
        (280, 'MONTE_ALEGRE', 35),
        (281, 'LITORAL_SUL', 32),
        (282, 'URUAÇU', 25),
        (283, 'NORTE', 48),
        (284, 'PORANGATU', 25),
        (285, 'CHAPADINHA', 45)
) AS polos_cosmos(polo_id, pol_nome, regional_id)

