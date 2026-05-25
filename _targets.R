# _targets.R
library(targets)
library(tarchetypes)
library(tidyverse)

# Carrega todas as funções da pasta core/R
lapply(list.files(here::here("core/R"), full.names = TRUE), source)
source(here::here("core/setup.R"))

tar_option_set(
  packages = c("tidyverse", "arrow", "microdatasus", "geobr", "sf", "janitor", "pointblank", "lubridate", "duckdb", "dbplyr"),
  format = "parquet"
)

list(
  tar_target(mun_br_meta, {
    geobr::read_municipality(year = 2022) %>% 
      janitor::clean_names() %>% 
      sf::st_drop_geometry() %>%
      transmute(code_uf = substr(as.character(code_muni), 1, 2), nome_uf = name_state) %>%
      distinct()
  }),
  
  tar_target(pop_base, get_pop_ibge(years = 2010:2024)),
  
  tar_target(transito_gold, {
    files <- list.files(here::here("data/raw/transito"), pattern = "sim_do_v_*.parquet", full.names = TRUE)
    
    res <- summarize_mortality_db(files) %>%
      standardize_race_groups(col = "raca_cor") %>% 
      left_join(mun_br_meta, by = "code_uf") %>%
      mutate(ano_num = as.numeric(substr(ano_trimestre, 1, 4))) %>%
      left_join(pop_base, by = c("code_uf", "raca_cor_agreg", "ano_num" = "ano")) %>%
      mutate(taxa_mortalidade = (total_obitos / populacao) * 100000)
    
    arrow::write_parquet(res, here::here("data/gold/transito_gold.parquet"))
    res
  })
)
