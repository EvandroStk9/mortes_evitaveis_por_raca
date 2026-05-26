# Mortes Evitáveis por Raça

Plataforma institucional de monitoramento territorializado de desigualdades raciais.

## Estrutura do Compêndio
- `data/`: Data Lakehouse local (`raw`, `staging`, `gold`).
- `src/`: Lógica de engenharia de dados.
    - `01_ingest.R`: Ingestão incremental via microdatasus.
    - `02_etl.R`: Limpeza, tipagem e padronização racial.
    - `03_modules_gen.R`: Gerador de tabelas agregadas para os módulos (COVID, MVI, APS).
- `app/`: Interface de visualização Shiny.
- `R/`: Funções utilitárias de suporte.

## Protocolo Racial (Benchmark COVID)
Para garantir comparabilidade, adotamos a agregação:
- **Branco ou Amarelo** (1, 3)
- **Preto ou Pardo** (2, 4)
- **Indígena** (5)

## Como utilizar
1. **Ambiente:** O projeto utiliza `renv` para gerenciar dependências.
2. **Setup:** Rode `source("main.R")` para executar o pipeline completo e subir o App.
   O `main.R` orquestra: `01_ingest.R` -> `02_etl.R` -> `03_modules_gen.R` -> `app/app.R`
