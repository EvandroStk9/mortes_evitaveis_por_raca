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
  packages = c("tidyverse", "arrow", "microdatasus", "geobr", "sf", "janitor", "pointblank"),
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
  
  # 1. Extrao
  tar_target(
    transito_raw,
    # Exemplo: filtrando causas externas de transporte (V01-V99)
    # fetch_sim_raw(years = 2010:2023, causa_prefix = "V")
    read_parquet("data/raw/transito/sim_do_v_2022.parquet") # Usando arquivo existente
  ),
  
  # 2. Tratamento (Staging) via DuckDB para performance
  tar_target(
    transito_gold,
    # Em vez de ler tudo para o R, usamos o DuckDB para agregar
    summarize_mortality_db("data/raw/transito/*.parquet") %>%
      standardize_race_groups(col = "raca_cor") %>% # Funo do ponto 18
      left_join(pop_base, by = c("code_uf", "raca_cor_agreg", "ano")) %>%
      mutate(taxa_mortalidade = (total_obitos / populacao) * 100000)
  ),
  
  # 3. Validao
  tar_target(
    transito_val,
    validate_gold_mortality(transito_stg),
    format = "qs" # Pointblank agents salvos em formato serializado
  )
)
