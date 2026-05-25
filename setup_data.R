# setup_data.R
library(tidyverse); library(arrow); library(janitor); library(here)

message("Iniciando processamento robusto...")

# Função de agregação racial com diagnóstico
processar_arquivo <- function(path, tipo = "transito") {
  df <- read_parquet(path) %>% clean_names()
  
  # Detecta coluna de raça (prioriza 'racacor' padrão SIM)
  col_raca <- intersect(names(df), c("racacor", "raca_cor", "raca"))
  raca_vals <- if(length(col_raca) > 0) df[[col_raca[1]]] else rep(9, nrow(df))
  
  # Detecta coluna de data
  col_data <- intersect(names(df), c("data_obito_raw", "dtobito", "data"))
  
  df %>%
    mutate(
      raca_agreg = case_when(
        raca_vals %in% c(1, 3) ~ "Branca/Amarela",
        raca_vals %in% c(2, 4) ~ "Preta/Parda",
        raca_vals == 5 ~ "Indígena",
        TRUE ~ "Ignorado/NI"
      ),
      ano = if("ano" %in% names(.)) as.character(ano) else substr(as.character(!!sym(col_data[1])), 5, 8)
    )
}

# --- 1. Processar Trânsito ---
files_t <- list.files(here("data/raw/transito"), pattern = "*.parquet", full.names = TRUE)
if(length(files_t) > 0) {
  df_t <- map_dfr(files_t, processar_arquivo) %>%
    group_by(ano, raca_agreg) %>%
    summarise(total = n(), .groups = "drop")
  write_parquet(df_t, here("data/gold/transito_gold.parquet"))
}

# --- 2. Processar COVID ---
path_c <- here("data/raw/covid/sim.parquet")
if(file.exists(path_c)) {
  df_c <- processar_arquivo(path_c) %>%
    group_by(ano, raca_agreg) %>%
    summarise(total = n(), .groups = "drop")
  write_parquet(df_c, here("data/gold/covid_gold.parquet"))
}
message("Processamento concluído.")
