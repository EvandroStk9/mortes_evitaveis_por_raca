# main.R
# Ponto de entrada modular: Orquestra Ingestão, ETL e Dashboard
library(here)

message("--- Executando Pipeline Completo ---")

# 1. Ingestão (Opcional: descomente na primeira execução)
source(here("src/01_ingest.R"))

# 2. ETL Modular
source(here("src/02_etl.R"))

# 3. Dashboard
shiny::runApp(here("src/03_app.R"))
