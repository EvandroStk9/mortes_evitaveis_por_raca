# _targets.R
# Arquivo central de orquestração do pipeline

library(targets)
library(tarchetypes)

# Carrega todas as funções da pasta core/R
lapply(list.files(here::here("core/R"), full.names = TRUE), source)
source(here::here("core/setup.R"))

# Opções do targets
tar_option_set(
  packages = c(
    "tidyverse", "arrow", "microdatasus", "geobr", "sf", 
    "janitor", "pointblank", "lubridate", "duckdb", "dbplyr"
  ),
  format = "parquet"
)

# Pipeline
list(
  # --- DADOS CORE ---
  
  tar_target(
    mun_br,
    geobr::read_municipality(year = 2022) %>% 
      janitor::clean_names() %>% 
      sf::st_drop_geometry(),
    format = "parquet"
  ),
  
  tar_target(
    pop_base,
    get_pop_ibge(years = 2010:2023)
  ),
  
  # --- MÓDULO TRÂNSITO ---
  
  # 1. Extração (Dependência de arquivos locais)
  tar_target(
    transito_raw_path,
    # Padrão para detecção de arquivos do módulo
    here::here("data/raw/transito/sim_do_v_2022.parquet"),
    format = "file"
  ),
  
  tar_target(
    transito_raw,
    read_parquet(transito_raw_path)
  ),
  
  # 2. Tratamento e Agregação via DuckDB
  tar_target(
    transito_gold,
    summarize_mortality_db(here::here("data/raw/transito/sim_do_v_*.parquet")) %>%
      standardize_race_groups(col = "raca_cor") %>% 
      left_join(pop_base, by = c("code_uf", "raca_cor_agreg", "ano")) %>%
      mutate(taxa_mortalidade = (total_obitos / populacao) * 100000)
  ),
  
  # 3. Validação
  tar_target(
    transito_val,
    validate_gold_mortality(transito_gold),
    format = "rds"
  )
)
