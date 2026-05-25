# _targets.R
# Arquivo central de orquestrao do pipeline

library(targets)
library(tarchetypes)

# Carrega todas as funes da pasta core/R
# Em projetos complexos, recomendvel usar o pacote 'box'
lapply(list.files("core/R", full.names = TRUE), source)
source("core/setup.R")

# Opes do targets
tar_option_set(
  packages = c(
    "tidyverse", "arrow", "microdatasus", "geobr", "sf", 
    "janitor", "pointblank", "lubridate", "duckdb", "dbplyr"
  ),
  format = "parquet"
)

# Pipeline
list(
  # --- CORE DATA ---
  
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
  
  # --- MDULO TRNSITO ---
  
  # 1. Extrao (Usando arquivo local como ponto de partida)
  tar_target(
    transito_raw_path,
    here::here("data/raw/transito/sim_do_v_2022.parquet"),
    format = "file"
  ),
  
  tar_target(
    transito_raw,
    read_parquet(transito_raw_path)
  ),
  
  # 2. Tratamento e Agregao via DuckDB
  tar_target(
    transito_gold,
    # L apenas arquivos sim_do_v_*.parquet para no dar erro de schema com pop/lookup
    summarize_mortality_db(here::here("data/raw/transito/sim_do_v_*.parquet")) %>%
      standardize_race_groups(col = "raca_cor") %>% 
      left_join(pop_base, by = c("code_uf", "raca_cor_agreg", "ano")) %>%
      mutate(taxa_mortalidade = (total_obitos / populacao) * 100000)
  ),
  
  # 3. Validao
  tar_target(
    transito_val,
    validate_gold_mortality(transito_gold),
    format = "rds" # Mudado de qs para rds para evitar erro de pacote
  )
)
