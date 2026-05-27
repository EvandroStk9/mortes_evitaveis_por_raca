# src/02_etl.R
# ETL: Raw -> Staging

library(tidyverse)
library(arrow)
library(here)
library(lubridate)
library(janitor)

message("--- Iniciando ETL: Raw -> Staging ---")

# =========================================================
# Diretórios
# =========================================================

raw_dir <- here("data/raw/sim")
staging_dir <- here("data/staging")

dir.create(
  staging_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# =========================================================
# Empilhamento da série histórica completa
# =========================================================

message("Empilhando série histórica completa...")

arquivos_raw <- list.files(
  raw_dir,
  pattern = "\\.parquet$",
  full.names = TRUE
)

# Remove eventual full_sim anterior da lista
arquivos_raw <- arquivos_raw[
  !str_detect(arquivos_raw, "full_sim\\.parquet$")
]

dataset_raw <- open_dataset(arquivos_raw)

full_sim_path <- here("data/raw/full_sim.parquet")

df_full_sim <- dataset_raw %>%
  collect()

write_parquet(
  df_full_sim,
  full_sim_path,
  compression = "zstd"
)

message("full_sim.parquet criado.")

# =========================================================
# Carrega base consolidada
# =========================================================

df_raw <- read_parquet(full_sim_path)

# =========================================================
# Padronização e Tipagem
# =========================================================

message("Transformando staging...")

df_staging <- df_raw %>%
  
  janitor::clean_names() %>%
  
  mutate(
    
    dtobito = as.Date(
      parse_date_time(
        as.character(dtobito),
        orders = c("dmy", "ymd")
      )
    ),
    
    ano = year(dtobito),
    
    mes = month(dtobito),
    
    ano_trimestre = paste0(
      ano,
      "-T",
      ceiling(mes / 3)
    ),
    
    causabas = as.character(causabas),
    
    raca_agreg = case_when(
      racacor %in% c("Branca", "Amarela") ~ "Branco ou Amarelo",
      racacor %in% c("Parda", "Preta") ~ "Preto ou Pardo",
      racacor == "Indígena" ~ "Indígena",
      TRUE ~ "Ignorado/NI"
    ),
    
    sexo = case_when(
      sexo %in% c("1", "M", "Masculino") ~ "Masculino",
      sexo %in% c("2", "F", "Feminino") ~ "Feminino",
      TRUE ~ "Não informado"
    )
    
  )

# =========================================================
# Salvar staging
# =========================================================

write_parquet(
  df_staging,
  here("data/staging/full_sim.parquet"),
  compression = "zstd"
)

message("Camada Staging criada com sucesso.")