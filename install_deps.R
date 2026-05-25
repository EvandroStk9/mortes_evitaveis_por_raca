# install_deps.R
# Script para instalar todas as dependências do projeto

message("Verificando e instalando dependências...")

pacotes <- c(
  "targets", "tarchetypes", "tidyverse", "arrow", "duckdb", 
  "dbplyr", "geobr", "sf", "janitor", "pointblank", 
  "shiny", "shinydashboard", "DT", "here", "qs", "lubridate", 
  "remotes", "ggthemes", "ggtext", "showtext", "sysfonts"
)

# Instala pacotes do CRAN
missing_cran <- setdiff(pacotes, rownames(installed.packages()))
if (length(missing_cran) > 0) {
  install.packages(missing_cran)
}

# Instala microdatasus do GitHub
if (!requireNamespace("microdatasus", quietly = TRUE)) {
  remotes::install_github("rfsaldanha/microdatasus")
}

message("Dependências verificadas.")
