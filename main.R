# main.R
# Script de entrada para a plataforma

# 1. Carregar ambiente
source("core/setup.R")

# 2. Executar Pipeline
message("Iniciando pipeline de dados...")
targets::tar_make()

# 3. Gerar Documentao (opcional)
# quarto::quarto_render("docs/metodologia.qmd")

message("Processamento completo.")
