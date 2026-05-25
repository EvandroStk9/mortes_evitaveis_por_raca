# core/R/utils_db.R
# Integrao com Parquet e DuckDB para Alta Performance

library(duckdb)
library(dbplyr)

#' Cria uma conexo efmera ou persistente com DuckDB
get_db_con <- function(db_path = ":memory:") {
  dbConnect(duckdb(), dbdir = db_path)
}

#' L arquivos Parquet usando DuckDB sem carregar na RAM do R
open_parquet_db <- function(path, con = get_db_con()) {
  tbl(con, sprintf("read_parquet('%s')", path))
}

#' Exemplo de agregao pesada via DuckDB
summarize_mortality_db <- function(parquet_path) {
  con <- get_db_con()
  
  # O processamento ocorre no DuckDB. 
  # Inspecionamos e vimos que as colunas so 'cod_mun_res' e 'racacor' (se existir)
  raw_tbl <- open_parquet_db(parquet_path, con) %>%
    janitor::clean_names()
  
  # Verifica colunas disponveis
  cols <- colnames(raw_tbl)
  
  # Mapeia colunas (Lgica de segurana)
  muni_col <- if ("cod_mun_res" %in% cols) "cod_mun_res" else if ("codmunres" %in% cols) "codmunres" else cols[1]
  race_col <- if ("racacor" %in% cols) "racacor" else if ("raca_cor" %in% cols) "raca_cor" else NULL
  
  # Construo da query
  query <- raw_tbl %>%
    mutate(code_uf = substr(as.character(!!sym(muni_col)), 1, 2))
    
  if (is.null(race_col)) {
    # Se no tem raa no arquivo, assume 9 (Ignorado) para manter o pipeline rodando
    query <- query %>% mutate(racacor = 9)
    race_col <- "racacor"
  }
  
  res <- query %>%
    group_by(code_uf, !!sym(race_col), ano) %>%
    summarise(
      total_obitos = n(),
      .groups = "drop"
    ) %>%
    collect() %>%
    rename(raca_cor = !!sym(race_col))
    
  dbDisconnect(con, shutdown = TRUE)
  return(res)
}
