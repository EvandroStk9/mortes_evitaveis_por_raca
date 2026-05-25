# apps/plataforma_monitoramento/global.R
library(shiny)
library(shinydashboard)
library(tidyverse)
library(arrow)
library(here)

source(here::here("core/setup.R"))
lapply(list.files(here::here("apps/plataforma_monitoramento/R"), full.names = TRUE), source)
source(here::here("core/R/utils_viz.R"))

# Função simplificada: Lê sempre do arquivo físico
get_gold_data <- function(file_name) {
  path <- here::here("data/gold", paste0(file_name, ".parquet"))
  if (file.exists(path)) {
    return(read_parquet(path))
  } else {
    message("Arquivo não encontrado em: ", path)
    return(NULL)
  }
}
