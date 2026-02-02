
# Performance Legacy

Este repositório contém o projeto DBT (Data Build Tool) responsável pela execução, transformação e padronização dos modelos legados de tabelas de dados e indicadores de performance operacional.
O objetivo principal é garantir a reprodutibilidade, governança e rastreabilidade das regras de negócio aplicadas aos indicadores atualmente em uso nos sistemas legados da operação.

# Inicialização

Antes de qualquer commit configurem o .gitignore para não trazer pastas desnecessárias conforme abaixo.
(podem copiar e colar no .gitignore)


    # Ignore dbt and build artifacts
    target/
    dbt_packages/
    logs/
    dbt_internal_packages/

    # Ignore Python virtual environment
    .venv/

    # Ignore VSCode settings
    .vscode/

    # Ignore All files starting with .
    .*

# Comandos de Execução
### dbt run
Executa todo o projeto DBT automatizando a escolha de ano e mês para o vigente/anterior até o dia 10 do mês subsequente.

### dbt run --vars '{"month_ref": "202509"}'
No caso de desejar rodar o projeto interior para um mês específico utilizem a variável month_ref com o ano e mês escritos no formato YYYYMM

### dbt run --select model
Esse método de execução irá apenas afetar o modelo utilizado no select, i.e. não irá alterar a referência de data nos modelos de referência.

Troquem "model" pelo modelo que desejam executar individualmente. 

Também funciona com variáveis ex:

    "dbt run --select programadas_fornecedor --vars '{"month_ref": "202509"}' 

### dbt run --select +model
***!!! ATENÇÃO !!!***

Esse método de execução irá afetar tanto o modelo como todas as referências em cadeia. Apenas utilize quando tiver certeza que não estará reescrevendo o passado de outros modelos.

Troquem "model" pelo modelo que desejam executar individualmente.

Também funciona com variáveis ex:

    "dbt run --select +programadas_fornecedor --vars '{"month_ref": "202509"}' 