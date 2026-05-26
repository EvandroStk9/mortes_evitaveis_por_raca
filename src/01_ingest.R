# src/01_ingest.R
# Script 1: Ingestão Incremental com Âncora no full_sim.parquet
library(tidyverse)
library(arrow)
library(here)
library(microdatasus)
library(lubridate)

dir.create(here("data/raw"), recursive = TRUE, showWarnings = FALSE)
meta_file <- here("data/raw/full_sim.parquet")

# 1. Âncora: Verifica a base consolidada
if (file.exists(meta_file)) {
  message("Lendo arquivo consolidado existente para definir ponto de partida...")
  base_info <- read_parquet(meta_file, col_select = any_of(c("dtobito", "DTOBITO"))) %>% 
    rename_with(tolower)
  
  # Extrai ano da data mais recente encontrada
  data_recente <- max(as.Date(parse_date_time(as.character(base_info$dtobito), orders = c("dmy", "ymd"))), na.rm = TRUE)
  ano_inicio <- year(data_recente)
} else {
  ano_inicio <- 2000
}

ano_fim <- year(today())
anos_necessarios <- ano_inicio:ano_fim

message("--- Ingestão Incremental: Sincronizando a partir de ", ano_inicio, " ---")

# 2. Download incremental (tudo para character para garantir stack)
consolidar_ano <- function(ano) {
  message("Processando ano: ", ano)
  fetch_datasus(year_start = ano, year_end = ano, uf = "all", information_system = "SIM-DO") %>% 
    process_sim() %>%
    mutate(across(everything(), as.character))
}

novos_dados <- map_dfr(anos_necessarios, consolidar_ano)

# 3. Consolidação final
if (file.exists(meta_file)) {
  base_antiga <- read_parquet(meta_file) %>% mutate(across(everything(), as.character))
  full_sim <- bind_rows(base_antiga, novos_dados) %>% distinct()
} else {
  full_sim <- novos_dados
}

write_parquet(full_sim, meta_file)
message("Base histórica consolidada em: ", meta_file)
