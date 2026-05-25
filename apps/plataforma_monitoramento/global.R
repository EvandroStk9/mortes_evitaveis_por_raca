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
get_gold_data <- function(target_name) {
  # Tenta ler do store do targets
  res <- tryCatch({
    # targets::tar_read_raw exige que o store exista
    if (dir.exists("../../_targets")) {
       targets::tar_read_raw(target_name, store = "../../_targets")
    } else {
      NULL
    }
  }, error = function(e) {
    # Fallback para o arquivo fsico em data/gold/ (caso exportado)
    path <- paste0("../../data/gold/", target_name, ".parquet")
    if (file.exists(path)) {
      arrow::read_parquet(path)
    } else {
      NULL
    }
  })
  return(res)
}
