# Observatório de Mortes Evitáveis por Raça/Cor

Este projeto fornece uma infraestrutura analítica robusta para o monitoramento de desigualdades raciais em mortes evitáveis no Brasil. A plataforma utiliza uma abordagem orientada a metadados para gerar módulos de análise dinâmicos sobre diferentes causas de óbito.

**Acesse o Dashboard:** [https://evandrostk9.shinyapps.io/mortes_evitaveis_por_raca/](https://evandrostk9.shinyapps.io/mortes_evitaveis_por_raca/)

---

## 🏗️ Arquitetura do Sistema

O projeto é estruturado em camadas de dados, garantindo performance e rastreabilidade:

1.  **Raw Layer (`data/raw`)**: Dados brutos do Sistema de Informações sobre Mortalidade (SIM), ingeridos via `microdatasus`.
2.  **Staging Layer (`data/staging`)**: Dados padronizados, com limpeza de nomes, tipagem de datas e recodificação de variáveis demográficas (Raça/Cor agregada e Sexo).
3.  **Gold Layer (`app/data`)**: Dados agregados e otimizados em formato `.parquet`, gerados dinamicamente para alimentar o dashboard.

## 🛠️ Motor de Geração (Metadata-Driven)

Diferente de dashboards estáticos, esta aplicação utiliza uma engine de processamento (`src/03_modules_gen.R`) que lê arquivos de configuração YAML na pasta `app/metadata/`. 

Cada arquivo YAML define:
- **ID e Nome** do módulo.
- **Regex de CID** para filtrar as causas de óbito.
- **Filtros temporais** específicos.

Isso permite adicionar novos temas de análise (ex: Homicídios, Doenças Cardiovasculares) sem alterar o código principal da aplicação.

## 📊 Visualizações e Funcionalidades

O dashboard foi projetado com foco em demografia racial e saúde pública:

-   **Módulos Independentes**: Cada causa de morte possui sua própria área de análise isolada.
-   **Filtros Dinâmicos**: Seleção por **Sexo** e **Causa Específica (CID)** com atualização em tempo real.
-   **Tendência Temporal**: Gráfico de linhas mostrando o número absoluto de óbitos por trimestre.
-   **Composição Racial**: Gráfico de barras empilhadas (100%) para visualizar a disparidade relativa entre raças, incluindo tooltips detalhados com **contagem absoluta e percentual**.
-   **Paleta Técnica**: Cores selecionadas para garantir acessibilidade e representação adequada dos grupos demográficos.

## 🚀 Como Executar

### Pré-requisitos
- R 4.x
- Pacotes listados no `renv.lock`

### Instalação e Execução
1.  **Restaurar Ambiente**:
    ```r
    renv::restore()
    ```
2.  **Executar Pipeline Completo**:
    Rode o arquivo `main.R` para processar os dados desde a ingestão até a camada Gold:
    ```r
    source("main.R")
    ```
3.  **Rodar Apenas o App**:
    ```r
    shiny::runApp("app/app.R")
    ```

## 📂 Estrutura de Pastas
- `app/`: Código fonte do dashboard e dados da camada Gold.
- `src/`: Scripts de processamento (ETL e Engine).
- `metadata/`: Arquivos YAML de configuração dos módulos.
- `data/`: Camadas intermediárias de dados (Raw e Staging).

---
*Desenvolvido como parte das iniciativas de análise de desigualdades raciais do Afro-Cebrap.*
