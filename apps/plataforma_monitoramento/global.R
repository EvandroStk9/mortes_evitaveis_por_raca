# apps/plataforma_monitoramento/global.R
library(shiny)
library(shinydashboard)
library(tidyverse)
library(targets)
library(DT)

# Carrega ambiente core
source("../../core/setup.R")
lapply(list.files("R", full.names = TRUE), source)

# Conexo com o Lakehouse (Targets)
# Em produo, leramos diretamente dos arquivos Parquet em data/gold/
get_gold_data <- function(target_name) {
  # Tenta ler do store do targets, se no existir, busca o arquivo parquet
  tryCatch({
    tar_read_raw(target_name, store = "../../_targets")
  }, error = function(e) {
    # Fallback para o arquivo fsico caso o store no esteja disponvel
    arrow::read_parquet(paste0("../../data/gold/", target_name, ".parquet"))
  })
}
