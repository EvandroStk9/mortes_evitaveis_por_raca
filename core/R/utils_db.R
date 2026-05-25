# core/R/utils_db.R
# Integração com Parquet e DuckDB - Versão Trimestral

library(duckdb)
library(dbplyr)
library(lubridate)

get_db_con <- function(db_path = ":memory:") {
  dbConnect(duckdb(), dbdir = db_path)
}

open_parquet_db <- function(path, con = get_db_con()) {
  tbl(con, sprintf("read_parquet('%s')", path))
}

summarize_mortality_db <- function(parquet_path) {
  con <- get_db_con()
  
  # Lógica de extração trimestral (YYYY-MM)
  res <- open_parquet_db(parquet_path, con) %>%
    janitor::clean_names() %>%
    # No SIM, a data costuma ser DTOBITO ou data_obito_raw (DDMMYYYY)
    # Criando coluna de data para o DuckDB processar
    mutate(
      code_uf = substr(as.character(cod_mun_res), 1, 2),
      # Extraindo mês e ano da string DDMMYYYY
      mes = substr(data_obito_raw, 3, 4),
      ano = substr(data_obito_raw, 5, 8),
      # Definindo o mês final do trimestre para o formato solicitado
      trimestre_mes = case_when(
        mes %in% c("01", "02", "03") ~ "03",
        mes %in% c("04", "05", "06") ~ "06",
        mes %in% c("07", "08", "09") ~ "09",
        mes %in% c("10", "11", "12") ~ "12",
        TRUE ~ "01"
      ),
      ano_trimestre = paste0(ano, "-", trimestre_mes)
    ) %>%
    # Verificação de raça (se não existir, mantemos Ignorado para não quebrar)
    mutate(racacor_final = if_else(any_of("racacor") %in% colnames(.), as.character(racacor), "9")) %>%
    group_by(code_uf, racacor_final, ano_trimestre) %>%
    summarise(
      total_obitos = n(),
      .groups = "drop"
    ) %>%
    collect() %>%
    rename(raca_cor = racacor_final)
    
  dbDisconnect(con, shutdown = TRUE)
  return(res)
}
