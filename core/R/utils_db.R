# core/R/utils_db.R
# Integrao com Parquet e DuckDB para Alta Performance

library(duckdb)
library(dbplyr)

#' Cria uma conexo efmera ou persistente com DuckDB
get_db_con <- function(db_path = ":memory:") {
  dbConnect(duckdb(), dbdir = db_path)
}

#' L arquivos Parquet usando DuckDB sem carregar na RAM do R
#' @param path Caminho para o arquivo ou diretrio de Parquets
open_parquet_db <- function(path, con = get_db_con()) {
  # Usa a funo read_parquet do DuckDB via SQL
  tbl(con, sprintf("read_parquet('%s')", path))
}

#' Exemplo de agregao pesada via DuckDB
#' @description Realiza a soma de bitos por UF e Raa usando o motor do DuckDB
summarize_mortality_db <- function(parquet_path) {
  con <- get_db_con()
  
  # O processamento abaixo ocorre no DuckDB, no no R
  res <- open_parquet_db(parquet_path, con) %>%
    group_by(code_uf, raca_cor, ano) %>%
    summarise(
      total_obitos = n(),
      .groups = "drop"
    ) %>%
    collect() # S traz o resultado final agregado para o R
    
  dbDisconnect(con, shutdown = TRUE)
  return(res)
}
