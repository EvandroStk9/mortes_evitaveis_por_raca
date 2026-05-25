# Proposta de Arquitetura: Plataforma de Monitoramento de Mortes Evitáveis e Desigualdades Raciais

Este documento detalha a infraestrutura analítica para o projeto **Mortes Evitáveis por Raça**, desenhada para ser escalável, modular e institucional.

## 1. Arquitetura do Sistema e Pipeline de Dados
A arquitetura segue o paradigma de **Functional Data Engineering** utilizando o framework `{targets}` em R.

- **Orquestração:** O pipeline é definido em um arquivo central `_targets.R`. Cada módulo (COVID, Trânsito, etc.) possui seu próprio conjunto de funções que são chamadas pelo orquestrador.
- **Camadas de Dados (Lakehouse):**
    - **Raw:** Dados brutos do DATASUS (DBC/CSV) e IBGE sem modificações.
    - **Staging:** Dados limpos, tipados e padronizados em formato Parquet.
    - **Gold:** Tabelas analíticas finais, agregadas por território e raça/cor, prontas para consumo.

## 2. Reorganização Modular
O repositório é estruturado como um monorepo modular:
- `core/`: Contém o "kernel" do sistema (código compartilhado para extração do SIM, tratamento geográfico e cálculo de indicadores base).
- `modules/`: Cada tema é um submódulo independente que herda métodos do `core`.
- `data/`: Armazenamento local persistente em Parquet.

## 3. Convenções de Nomenclatura e Governança
- **Arquivos:** `snake_case`. Scripts funcionais prefixados por sua ordem ou função (ex: `fct_calcula_indicadores.R`).
- **Objetos R:** Verbos para funções (`get_data`, `process_sim`), substantivos para dados (`df_populacao`).
- **Camadas:** `stg_` (staging), `int_` (intermediate), `fct_` (final/facts).

## 4. Convenções Territoriais e Harmonização
- **Padrão:** Código IBGE de 7 dígitos.
- **Harmonização:** Implementação de uma tabela de `de-para` histórica para municípios extintos ou criados, garantindo séries temporais consistentes desde 2000.
- **Níveis:** Nacional, Regional, Estadual, Macrorregião de Saúde, Município.

## 5. Convenções de Indicadores e Metadados
- **Taxas:** Sempre calculadas por 100.000 habitantes, ajustadas por idade quando necessário (padronização direta).
- **Metadados:** Cada indicador terá um arquivo YAML associado descrevendo a fórmula, fonte, granularidade e data de atualização.

## 6. Integração Parquet e DuckDB
- **Armazenamento:** `.parquet` para compressão e particionamento (ex: `data/gold/covid/ano=2021/data.parquet`).
- **Processamento:** Uso do `{duckdb}` via `{dbplyr}` para realizar agregações pesadas em memória sem carregar todo o dataset no R.

## 7. Infraestrutura Shiny Modular
- **Framework:** Uso de módulos Shiny (`moduleServer`) para isolar a lógica de cada visualização.
- **Separação:** O Shiny não realiza processamento de dados pesado; ele apenas lê as tabelas "Gold" do Lakehouse.

## 8. Validação e Testes
- **Data Quality:** `{pointblank}` para testar se as taxas estão dentro de limites esperados e se não há NAs em colunas críticas (Raça/Cor).
- **Unit Tests:** `{testthat}` para garantir que as funções de cálculo de indicadores estão corretas.

## 9. Tratamento de Raça/Cor
- **Padronização:** Categorias IBGE (Branca, Preta, Parda, Amarela, Indígena).
- **Tratamento de Missing:** Protocolo explícito para "Ignorados". Cálculo de disparidade absoluta e relativa (Rate Ratio).

## 10. Automação e DevOps
- **GitHub Actions:** Pipeline semanal para checar novos dados no FTP do DATASUS.
- **Versionamento:** Uso de tags Git para versionar "snapshots" dos indicadores produzidos.

---
**Próximos Passos:**
1. Implementação do `core/` para extração universal de SIM.
2. Migração do módulo de COVID para a nova estrutura.
3. Migração do módulo de Trânsito.
