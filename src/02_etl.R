# src/02_etl.R
# Script 2: ETL - Staging e Gold (Tipagem robusta no processamento)
library(tidyverse); library(arrow); library(here); library(janitor); library(lubridate)

message("--- Iniciando ETL (Tipagem forçada) ---")

base_path <- here("data/raw/full_sim.parquet")
if(!file.exists(base_path)) stop("Base raw não encontrada. Rode src/01_ingest.R primeiro.")

# Lê como char e força tipos no mutate
df_staging <- read_parquet(base_path) %>% 
  clean_names() %>%
  mutate(
    # Conversão explícita para tipos de análise
    dtobito = parse_date_time(dtobito, orders = c("dmy", "ymd")),
    racacor = as.numeric(racacor),
    sexo = as.numeric(sexo),
    idade = as.numeric(idade),
    
    # Padronização Racial (Benchmark COVID)
    raca_agreg = case_when(
      racacor %in% c(1, 3) ~ "Branco ou Amarelo",
      racacor %in% c(2, 4) ~ "Preto ou Pardo",
      racacor == 5 ~ "Indígena",
      TRUE ~ "Ignorado/NI"
    ),
    genero = case_when(
      sexo == 1 ~ "Homem",
      sexo == 2 ~ "Mulher",
      TRUE ~ "Ignorado/NI"
    ),
    ano = format(dtobito, "%Y"),
    ano_trimestre = paste0(ano, "-T", quarter(dtobito))
  ) %>%
  filter(!is.na(dtobito), idade >= 18, idade <= 65)

dir.create(here("data/staging"), showWarnings = FALSE, recursive = TRUE)
write_parquet(df_staging, here("data/staging/full_pea_sim.parquet"))

# Processamento Modular
dir.create(here("data/gold"), showWarnings = FALSE, recursive = TRUE)

processar_modulo <- function(df, filtro_causa, nome_modulo) {
  df %>%
    filter(eval(parse(text = filtro_causa))) %>%
    group_by(ano_trimestre, raca_agreg, genero, causabas) %>%
    summarise(total = n(), .groups = "drop") %>%
    write_parquet(here(paste0("data/gold/", nome_modulo, "_gold.parquet")))
}

processar_modulo(df_staging, "str_detect(causabas, '^[V|W|X|Y]')", "transito")
processar_modulo(df_staging, "causabas == 'B342'", "covid")
processar_modulo(df_staging, "str_detect(causabas, '^[A|B|E|I|J]')", "aps")

message("ETL Gold concluído.")
