# Aderência de Execução - KPI

## 📋 Descrição

Este módulo contém os modelos para cálculo do KPI de **Aderência de Execução da Programação**, que mede o percentual de obras programadas que foram executadas dentro da janela de tempo estabelecida.

## 🏗️ Estrutura

```
models/aderencia_execucao/
├── intermediate/           # Modelos intermediários (views)
│   ├── int_dimempreiteira.sql    # Dimensão de empreiteiras
│   ├── int_fequipes.sql          # Fato de equipes
│   ├── int_fprogamacao.sql       # Fato de programação
│   └── sources.yml               # Definições de sources
└── marts/                 # Modelos finais (gold)
    └── kpi_aderencia_execucao.sql  # KPI final incremental
```

## 📊 Modelos

### Intermediate (Silver)

#### `int_dimempreiteira`
- **Materialização**: View
- **Schema**: silver
- **Descrição**: Dimensão de empreiteiras com informações de regional, empresa, contrato e processo
- **Fonte**: EQTLINFO_RAW.SIPROG.EMPREITEIRA, AGRUPADOR, AGRUPADOR_VALOR

#### `int_fequipes`
- **Materialização**: View
- **Schema**: silver
- **Descrição**: Fato de equipes com valor de referência, agrupadores e informações de empresa
- **Fonte**: EQTLINFO_RAW.SIPROG.EQUIPE, EMPREITEIRA, AGRUPADOR_VALOR

#### `int_fprogamacao`
- **Materialização**: View
- **Schema**: silver
- **Descrição**: Fato de programação com todas as informações de obras, datas, status e classificações
- **Fonte**: EQTLINFO_RAW.SIPROG.PROGRAMACAO + múltiplos JOINs com AGRUPADOR_VALOR

### Marts (Gold)

#### `kpi_aderencia_execucao`
- **Materialização**: Incremental
- **Schema**: gold
- **Unique Key**: `['EMPRESA', 'REGIONAL', 'CONTRATO', 'PROCESSO', 'ANO', 'MES']`
- **Descrição**: KPI de aderência da programação calculado mensalmente
- **Métricas**:
  - `EXECUTADO`: Obras executadas dentro da janela
  - `PROGRAMADO`: Total de obras programadas
  - `ADERENCIA`: Percentual de aderência (EXECUTADO / PROGRAMADO * 100)

## 🔄 Lógica de Negócio

### Janela de Apontamento
A lógica define quando uma execução é considerada "dentro da janela":

1. **Competência 202529 (Julho/2025)**: Janela até 25/07/2025
2. **Outras competências**: Janela até 3 dias após o fim da semana programada

### Critérios de Aderência
- ✅ **EXECUTADO**: Programação executada = 'SIM' E dentro da janela
- 📋 **PROGRAMADO**: Programação em ['SIM', 'REPROGRAMADA', 'PARCIALMENTE', 'OBRA CANCELADA'] ou NULL

## 🚀 Como Executar

### Executar todos os modelos
```bash
dbt run --select aderencia_execucao
```

### Executar apenas intermediários
```bash
dbt run --select aderencia_execucao.intermediate
```

### Executar apenas o KPI final
```bash
dbt run --select kpi_aderencia_execucao
```

### Full Refresh do KPI
```bash
dbt run --select kpi_aderencia_execucao --full-refresh
```

## 📅 Incrementalidade

O modelo `kpi_aderencia_execucao` é incremental e usa a macro `get_month_ref()` para:
- Deletar dados do mês de referência antes de inserir novos
- Processar apenas dados do mês de referência

## 🏷️ Tags

- `aderencia_execucao`: Todos os modelos do módulo
- `intermediate`: Modelos intermediários
- `kpi`: Indicadores de performance
- `gold`: Camada final de dados

## 📝 Observações

- As tabelas `SIPROG_OURO__VIEW__DIM_TEMPO` são referenciadas diretamente (não via source) pois fazem parte do schema EQTL_CORP
- O cálculo considera regras específicas de janela para diferentes competências
- Regiões do Piauí (CENTRO/SUL) são mapeadas para PICOS/FLORIANO

