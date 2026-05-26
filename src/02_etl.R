# src/02_etl.R
# ETL: Limpeza e Tipagem (Raw -> Staging)
library(tidyverse)
library(arrow)
library(here)
library(lubridate)

message("--- Iniciando ETL: Raw -> Staging ---")

# Carrega base bruta
df_raw <- read_parquet(here("data/raw/full_sim.parquet"))

# Padronização e Tipagem
df_staging <- df_raw %>%
  janitor::clean_names() %>% # Padroniza nomes das colunas
  mutate(
    # Conversão de datas
    dtobito = as.Date(parse_date_time(as.character(dtobito), orders = c("dmy", "ymd"))),
    ano = year(dtobito),
    mes = month(dtobito),
    ano_trimestre = paste0(ano, "-T", ceiling(mes/3)),
    # Variáveis de interesse
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

# Salva na camada staging
dir.create(here("data/staging"), recursive = TRUE, showWarnings = FALSE)
write_parquet(df_staging, here("data/staging/full_sim.parquet"))

message("Camada Staging criada com sucesso.")
