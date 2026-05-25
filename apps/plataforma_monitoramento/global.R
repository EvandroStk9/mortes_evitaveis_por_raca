# apps/plataforma_monitoramento/global.R
library(shiny)
library(shinydashboard)
library(tidyverse)
library(targets)
library(DT)
library(arrow)
library(here)

# Garante que o ambiente core e utilitários sejam carregados de caminhos absolutos
source(here::here("core/setup.R"))
lapply(list.files(here::here("apps/plataforma_monitoramento/R"), full.names = TRUE), source)
source(here::here("core/R/utils_viz.R"))

# Função Robusta para carregar dados Gold
get_gold_data <- function(target_name) {
  store_path <- here::here("_targets")
  
  # 1. Tenta ler do Targets Store
  res <- tryCatch({
    if (dir.exists(store_path)) {
      targets::tar_read_raw(target_name, store = store_path)
    } else {
      NULL
    }
  }, error = function(e) NULL)
  
  # 2. Fallback para arquivo físico se o targets falhar ou retornar NULL
  if (is.null(res)) {
    path_gold <- here::here("data/gold", paste0(target_name, ".parquet"))
    if (file.exists(path_gold)) {
      res <- arrow::read_parquet(path_gold)
    }
  }
  
  return(res)
}

# Carregamento auxiliar de dados de staging
load_platform_data <- function(file_name) {
  path <- here::here("data/staging/transito", file_name)
  if (file.exists(path)) {
    return(read_parquet(path))
  }
  return(NULL)
}
