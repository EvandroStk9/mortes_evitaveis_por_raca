# main.R
# Ponto de entrada unificado para o projeto

# 1. Instalação e carregamento de dependências
source("install_deps.R")
library(targets)
library(tidyverse)

# 2. Execução do pipeline
message("Iniciando processamento de dados...")
tryCatch({
  tar_make()
  message("Pipeline executado com sucesso!")
}, error = function(e) {
  message("Erro no pipeline: ", e$message)
})

# 3. Inicialização do Dashboard
message("Abrindo Dashboard...")
shiny::runApp('apps/plataforma_monitoramento')
