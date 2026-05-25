# processamento.R
library(tidyverse)
library(arrow)
library(duckdb)
library(geobr)
library(janitor)
library(here)

source(here::here("core/setup.R"))
lapply(list.files(here::here("core/R"), full.names = TRUE), source)

message("Iniciando processamento linear...")

# 1. Metadados UF
mun_br_meta <- geobr::read_municipality(year = 2022) %>% 
  janitor::clean_names() %>% 
  sf::st_drop_geometry() %>%
  transmute(code_uf = substr(as.character(code_muni), 1, 2), nome_uf = name_state) %>%
  distinct()

# 2. Pop base
pop_base <- get_pop_ibge(years = 2010:2024)

# 3. Transito Gold
raw_path <- here::here("data/raw/transito")
files <- list.files(raw_path, pattern = "sim_do_v_.*\\.parquet$", full.names = TRUE, recursive = TRUE)

message("Arquivos encontrados: ", length(files))

if(length(files) > 0) {
  res <- summarize_mortality_db(files) %>%
    standardize_race_groups(col = "raca_cor") %>% 
    left_join(mun_br_meta, by = "code_uf") %>%
    mutate(ano_num = as.numeric(substr(ano_trimestre, 1, 4))) %>%
    left_join(pop_base, by = c("code_uf", "raca_cor_agreg", "ano_num" = "ano")) %>%
    mutate(taxa_mortalidade = (total_obitos / populacao) * 100000)
  
  dir.create(here::here("data/gold"), showWarnings = FALSE, recursive = TRUE)
  arrow::write_parquet(res, here::here("data/gold/transito_gold.parquet"))
  message("Processamento concluído. Arquivo salvo em: data/gold/transito_gold.parquet")
} else {
  stop("ERRO: Nenhum arquivo encontrado.")
}
