# src/03_modules_gen.R
# Script 03: Gerador de Módulos Gold
# Este script cria os arquivos agregados para cada módulo analítico
library(tidyverse); library(arrow); library(here)

message("--- Gerando Módulos Gold ---")

# Carrega base tratada (Staging)
df_staging <- read_parquet(here("data/staging/full_pea_sim.parquet"))

# Função de agregação modular
processar_modulo <- function(df, filtro, nome) {
  df %>%
    filter(eval(parse(text = filtro))) %>%
    group_by(ano_trimestre, raca_agreg, genero, causabas) %>%
    summarise(total = n(), .groups = "drop") %>%
    write_parquet(here(paste0("data/gold/", nome, "_gold.parquet")))
}

dir.create(here("data/gold"), showWarnings = FALSE, recursive = TRUE)

# Execução
processar_modulo(df_staging, "str_detect(causabas, '^[V|W|X|Y]')", "transito")
processar_modulo(df_staging, "causabas == 'B342'", "covid")
processar_modulo(df_staging, "str_detect(causabas, '^[A|B|E|I|J]')", "aps")

message("Módulos Gold gerados.")
