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
  # O SIM costuma ter CODMUNRES ou codmunres. DuckDB read_parquet costuma ler como minusculo.
  res <- open_parquet_db(parquet_path, con) %>%
    # Garante nomes padronizados para a query
    janitor::clean_names() %>%
    # Extrai UF (primeiros 2 digitos do municipio)
    mutate(code_uf = substr(as.character(codmunres), 1, 2)) %>%
    group_by(code_uf, racacor, ano) %>%
    summarise(
      total_obitos = n(),
      .groups = "drop"
    ) %>%
    collect() %>%
    # Renomeia para bater com o restante do pipeline
    rename(raca_cor = racacor)
    
  dbDisconnect(con, shutdown = TRUE)
  return(res)
}
