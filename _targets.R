# _targets.R
# Arquivo central de orquestração do pipeline - Versão Trimestral

library(targets)
library(tarchetypes)

lapply(list.files(here::here("core/R"), full.names = TRUE), source)
source(here::here("core/setup.R"))

tar_option_set(
  packages = c(
    "tidyverse", "arrow", "microdatasus", "geobr", "sf", 
    "janitor", "pointblank", "lubridate", "duckdb", "dbplyr"
  ),
  format = "parquet"
)

list(
  # 1. Metadados de UF (Core)
  tar_target(
    mun_br_meta,
    geobr::read_municipality(year = 2022) %>% 
      janitor::clean_names() %>% 
      sf::st_drop_geometry() %>%
      transmute(code_uf = substr(as.character(code_muni), 1, 2), nome_uf = name_state) %>%
      distinct()
  ),
  
  # 2. População (Core) - Adaptada para Join Trimestral
  tar_target(
    pop_base,
    get_pop_ibge(years = 2010:2024)
  ),
  
  # 3. Módulo Trânsito Gold
  tar_target(
    transito_gold,
    summarize_mortality_db(here::here("data/raw/transito/sim_do_v_*.parquet")) %>%
      # Adiciona nomes de UF
      left_join(mun_br_meta, by = "code_uf") %>%
      # Padroniza Raça
      standardize_race_groups(col = "raca_cor") %>% 
      # Join com população (Nota: taxa trimestral usa pop anual como base)
      mutate(ano_num = as.numeric(substr(ano_trimestre, 1, 4))) %>%
      left_join(pop_base, by = c("code_uf", "raca_cor_agreg", "ano_num" = "ano")) %>%
      # Taxa Trimestral (Óbitos no trimestre / Pop Anual * 100k)
      mutate(taxa_mortalidade = (total_obitos / populacao) * 100000)
  )
)
