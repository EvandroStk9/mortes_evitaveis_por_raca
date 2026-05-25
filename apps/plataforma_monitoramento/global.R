# apps/plataforma_monitoramento/global.R
library(shiny)
library(shinydashboard)
library(tidyverse)
library(targets)
library(DT)
library(arrow)

# Carrega ambiente core e utilitários de visualização
source("../../core/setup.R")
lapply(list.files("R", full.names = TRUE), source)
source("../../core/R/utils_viz.R")

# Função para carregar dados de qualquer fonte disponível
load_platform_data <- function(file_name) {
  # Tenta primeiro no staging (dados originais importados)
  staging_path <- file.path("../../data/staging/transito", file_name)
  
  if (file.exists(staging_path)) {
    return(read_parquet(staging_path))
  }
  
  # Se não existir, tenta no targets store
  tryCatch({
    tar_read_raw(gsub(".parquet", "", file_name), store = "../../_targets")
  }, error = function(e) NULL)
}
