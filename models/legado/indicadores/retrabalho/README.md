# Modelos de Retrabalho

Este diretório contém os modelos de dados relacionados ao retrabalho, organizados por região.

## 📁 Estrutura do Diretório

```
models/retrabalho/
├── README.md                    # Documentação
├── intermediate/                # Modelos intermediários por região
│   ├── sources.yml             # Definições de sources consolidadas (todas as regiões)
│   ├── int_os_comercial_perdas_al.sql
│   ├── int_os_comercial_perdas_ap.sql
│   ├── int_os_comercial_perdas_go.sql
│   ├── int_os_comercial_perdas_ma.sql
│   ├── int_os_comercial_perdas_pa.sql
│   ├── int_os_comercial_perdas_pi.sql
│   ├── int_os_comercial_perdas_rs.sql
│   ├── int_os_comercial_siga_al.sql
│   ├── int_os_comercial_siga_ap.sql
│   ├── int_os_comercial_siga_ma.sql
│   ├── int_os_comercial_al.sql
│   ├── int_os_comercial_go.sql
│   ├── int_os_comercial_pa.sql
│   ├── int_os_comercial_pi.sql
│   ├── int_os_comercial_rs.sql
│   ├── int_os_emergencial_al.sql
│   ├── int_os_emergencial_go.sql
│   ├── int_os_emergencial_pa.sql
│   ├── int_os_emergencial_pi.sql
│   ├── int_os_emergencial_rs.sql
│   ├── int_os_emergencial_siga_al.sql
│   ├── int_os_emergencial_siga_ap.sql
│   ├── int_os_emergencial_siga_ma.sql
│   ├── int_os_merge_full_al.sql
│   ├── int_os_merge_full_ap.sql
│   ├── int_os_merge_go.sql
│   ├── int_os_merge_oper_al.sql
│   ├── int_os_merge_pa.sql
│   ├── int_os_merge_pi.sql
│   ├── int_os_merge_rs.sql
│   ├── int_os_merge_siga_al.sql
│   ├── int_os_merge_siga_ap.sql
│   └── int_os_merge_siga_ma.sql
│
└── marts/                      # Modelos finais por região
    ├── retrabalho_al.sql
    ├── retrabalho_ap.sql
    ├── retrabalho_go.sql
    ├── retrabalho_ma.sql
    ├── retrabalho_pa.sql
    ├── retrabalho_pi.sql
    └── retrabalho_rs.sql
```

## 🗺️ Regiões

- **AL** - Alagoas
- **AP** - Amapá
- **GO** - Goiás
- **MA** - Maranhão
- **PA** - Pará
- **PI** - Piauí
- **RS** - Rio Grande do Sul

## 📝 Padrão de Nomenclatura

Todos os modelos seguem o padrão DBT com sufixo regional para evitar conflitos:

- **Intermediate**: `int_<nome>_<região>.sql`
  - Exemplo: `int_os_comercial_al.sql`, `int_os_merge_pa.sql`
- **Marts**: `retrabalho_<região>.sql`
  - Exemplo: `retrabalho_al.sql`, `retrabalho_pi.sql`

## 🔗 Referências Internas

Todos os modelos usam `ref()` para referenciar outros models, com o sufixo regional correto:

```sql
-- Exemplo em retrabalho_pa.sql
SELECT * FROM {{ ref('int_os_merge_pa') }}

-- Exemplo em int_os_merge_pa.sql
SELECT * FROM {{ ref('int_os_emergencial_pa') }}
UNION ALL
SELECT * FROM {{ ref('int_os_comercial_pa') }}
```

## 📊 Sources

O arquivo `intermediate/sources.yml` contém as definições de sources para **todas as 7 regiões**:

- **OPER_AL, OPER_AP, OPER_GO, OPER_MA, OPER_PA, OPER_PI, OPER_RS** - Dados operacionais RAW
- **EQTL_AL_PERFORMANCE, EQTL_AP_PERFORMANCE, ...** - Tabelas de performance
- **EQTL_AL, EQTL_AP, ...** - Dados PRD
- **SIGA** - Sistema SIGA (compartilhado)

## 🚀 Como usar

```bash
# Executar todos os modelos de retrabalho
dbt run --select retrabalho

# Executar apenas uma região específica
dbt run --select retrabalho_al
dbt run --select retrabalho_ap
dbt run --select retrabalho_go
dbt run --select retrabalho_ma
dbt run --select retrabalho_pa
dbt run --select retrabalho_pi
dbt run --select retrabalho_rs

# Executar todos os intermediate de uma região (exemplo: PA)
dbt run --select int_os*_pa

# Executar todos os models de uma região (intermediate + mart)
dbt run --select +retrabalho_pa
```

## 🔄 Migração dos Projetos Separados

Este diretório foi criado pela migração de 7 projetos DBT separados em um único projeto unificado:

- ✅ Projetos originais movidos para `projetos/` (fora de models/)
- ✅ Models copiados com sufixo regional
- ✅ Referências internas (`ref()`) atualizadas automaticamente
- ✅ Sources consolidados em um único arquivo
- ✅ Padrão DBT aplicado (estrutura flat com sufixos)

## ⚠️ Importante

- **Não modifique** os projetos originais em `projetos/` - eles são mantidos apenas para referência
- **Use sempre** os sufixos regionais nos nomes dos models
- **Atualize** o `sources.yml` se novas tabelas forem adicionadas
- **Teste** sempre com `dbt compile` antes de fazer `dbt run`
