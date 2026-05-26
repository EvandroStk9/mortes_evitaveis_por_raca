# Mortes Evitáveis por Raça: Compêndio Analítico

Esta plataforma fornece infraestrutura para monitoramento territorializado de desigualdades raciais e mortes evitáveis no Brasil.

## Arquitetura do Sistema

O sistema é dividido em três camadas:

1.  **Ingestão (`src/01_ingest.R`)**: Extração via `microdatasus` (SIM-DO). Otimizado para 18GB RAM.

2.  **Transformação (`src/02_etl.R` e `src/03_modules_gen.R`)**: Padronização racial (Benchmark COVID: Branco/Amarelo, Preto/Pardo, Indígena), filtro de PEA e agregação em arquivos `gold/`.

3.  **Apresentação (`app/app.R`)**: Dashboard interativo focado em dados tratados.

## Protocolo Racial e de Gênero

Todos os módulos (Trânsito, COVID, APS) seguem a norma institucional de agregação racial validada para garantir comparabilidade entre as causas de morte.

## Como Executar

1.  Instale o ambiente: `renv::restore()`
2.  Ingestão/ETL: `source("main.R")`
3.  Dashboard: `shiny::runApp("app/app.R")`
