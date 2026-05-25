# install_deps.R
# Script para instalar todas as dependncias do projeto

message("Verificando e instalando dependncias...")

pacotes <- c(
  "targets", "tarchetypes", "tidyverse", "arrow", "duckdb", 
  "dbplyr", "geobr", "sf", "janitor", "pointblank", 
  "shiny", "shinydashboard", "DT", "here", "qs", "lubridate", "remotes"
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

message("Dependncias verificadas.")
