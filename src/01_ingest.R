# src/01_ingest.R
# Script 1: Ingestão de Série Histórica - Conversão para character para garantir stack
library(tidyverse); library(arrow); library(here); library(microdatasus); library(lubridate)

dir.create(here("data/raw"), recursive = TRUE, showWarnings = FALSE)
meta_file <- here("data/raw/full_sim.parquet")

# 1. Carrega o que já existe se houver
if(file.exists(meta_file)) {
  message("Carregando base existente para empilhar...")
  base_existente <- read_parquet(meta_file) %>% mutate(across(everything(), as.character))
} else {
  base_existente <- tibble()
}

# 2. Determina anos a baixar (ou reprocessar tudo se desejar garantir a tipagem)
# Aqui estamos apenas baixando o que é necessário, mas tipando como character
ano_fim <- year(today())
anos <- 2000:ano_fim

message("--- Consolidando base histórica (2000-", ano_fim, ") ---")

consolidar_ano <- function(ano) {
  message("Processando ano: ", ano)
  df <- fetch_datasus(year_start = ano, year_end = ano, uf = "all", information_system = "SIM-DO") %>%
    mutate(across(everything(), as.character)) # Força tipagem character
  return(df)
}

# 3. Baixa e Empilha
novos_dados <- map_dfr(anos, consolidar_ano)

# 4. Consolida com o que já existia (se houver)
full_sim <- bind_rows(base_existente, novos_dados) %>% distinct()

# 5. Salva arquivo único
write_parquet(full_sim, meta_file)
message("Base histórica consolidada e tipada como character em: ", meta_file)
