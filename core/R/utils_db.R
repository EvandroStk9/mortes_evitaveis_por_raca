# core/R/utils_db.R
# Integração com Parquet e DuckDB - Versão Trimestral Robusta

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
  
  # 1. Carrega tabela bruta e padroniza nomes para inspeção
  raw_tbl <- open_parquet_db(parquet_path, con) %>%
    janitor::clean_names()
  
  cols <- colnames(raw_tbl)
  
  # 2. Identifica colunas dinamicamente
  muni_col <- if ("cod_mun_res" %in% cols) "cod_mun_res" else if ("codmunres" %in% cols) "codmunres" else cols[1]
  data_col <- if ("data_obito_raw" %in% cols) "data_obito_raw" else if ("dtobito" %in% cols) "dtobito" else cols[1]
  race_col <- if ("racacor" %in% cols) "racacor" else if ("raca_cor" %in% cols) "raca_cor" else NULL
  
  # 3. Constrói a Query
  query <- raw_tbl %>%
    mutate(
      code_uf = substr(as.character(!!sym(muni_col)), 1, 2),
      # Assume DDMMYYYY ou similar
      mes = substr(as.character(!!sym(data_col)), 3, 4),
      ano = substr(as.character(!!sym(data_col)), 5, 8),
      trimestre_mes = case_when(
        mes %in% c("01", "02", "03") ~ "03",
        mes %in% c("04", "05", "06") ~ "06",
        mes %in% c("07", "08", "09") ~ "09",
        mes %in% c("10", "11", "12") ~ "12",
        TRUE ~ "03"
      ),
      ano_trimestre = paste0(ano, "-", trimestre_mes)
    )
    
  # Adiciona raça se existir, caso contrário assume 9 (Ignorado)
  if (!is.null(race_col)) {
    query <- query %>% rename(raca_val = !!sym(race_col))
  } else {
    query <- query %>% mutate(raca_val = "9")
  }
  
  # 4. Agregação Final
  res <- query %>%
    group_by(code_uf, raca_val, ano_trimestre) %>%
    summarise(
      total_obitos = n(),
      .groups = "drop"
    ) %>%
    collect() %>%
    rename(raca_cor = raca_val)
    
  dbDisconnect(con, shutdown = TRUE)
  return(res)
}
