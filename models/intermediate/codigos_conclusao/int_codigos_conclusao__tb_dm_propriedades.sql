select 
    a.*,
    replace(split(tx_chave,'_')[1],'"','') OSTIPO,
    replace(split(tx_chave,'_')[2],'"','') GRUPO_CODE,
    replace(split(tx_chave,'_')[3],'"','') GRUPO_MEDIDA,
    replace(split(tx_chave,'_')[4],'"','') CODE_MEDIDA,
    UPPER(TX_VALOR) DESCRICAO,
    CASE
        when tx_ref = 'EQ_TipoConclusaoExecutada' then 'N'
        when tx_ref = 'EQ_TipoConclusaoNaoExecutada' then 'R'
    end as TIPO_CONCLUSAO
from {{ ref('tb_dm_propriedades') }} a