# src/03_modules_gen.R
# Gerador de Módulos (Engine de Agregação: Staging -> Gold)
library(tidyverse)
library(arrow)
library(here)
library(yaml)

message("--- Gerando módulos analíticos (Gold Layer) ---")

# Carrega base tratada (Staging)
df_staging <- read_parquet(here("data/staging/full_sim.parquet"))

# Engine processadora (Metadata-Driven)
run_metadata_engine <- function(yaml_file) {
  meta <- yaml::read_yaml(yaml_file)
  message("Gerando arquivo Gold para: ", meta$nome)
  
  # Filtro dinâmico
  df_filtered <- df_staging %>%
    filter(
      str_detect(causabas, meta$metodologia$cid_regex) &
      ano >= meta$metodologia$filtros$ano_inicio 
      )
  
  # Agregação dinâmica
  agregacoes <- rlang::syms(meta$metodologia$agregacoes)
  
  df_agregado <- df_filtered %>%
    group_by(!!!agregacoes) %>%
    summarise(total = n(), .groups = "drop")
    
  write_parquet(df_agregado, here(paste0("data/gold/", meta$id, "_gold.parquet")))
}

# Execução
dir.create(here("data/gold"), showWarnings = FALSE)
yaml_files <- list.files(here("metadata"), "*.yaml", full.names = TRUE)
walk(yaml_files, run_metadata_engine)

message("Módulos Gold gerados com sucesso.")
