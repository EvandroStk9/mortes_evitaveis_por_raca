# teste
# 0. Setup ---------------------------------------------------------------------

# Abre o RProject e toma a pasta do RProject como diretório root

# Taxonomia:
# snake_case para pastas
# 1_snake_case para scripts
# snake_case para funções

# Vê pacotes/livrarias instalados
tibble::tibble(
  Package = names(installed.packages()[,3]),
  Version = unname(installed.packages()[,3])
)

#
sessionInfo()

#
writeLines(capture.output(sessionInfo()), here::here("r", "sessionInfo.txt"))

# 1. Estrutura -----------------------------------------------------------------
#testeLuiza
#
fs::dir_tree()

#
fs::dir_tree("data")

#
fs::dir_tree("r")

# 2. ETL ------------------------------------------------------------------------

# 01 - Trata dados do SIM e integra com dados de interesse (CBO e Geo)
# Exporta SIM curated para "data" em formato parquet
tictoc::tic()
source(here::here("r", "01_sim_tratamento.R"))
tictoc::toc() # 341.96 sec/ 05:41 min
rm(list = ls()) 


# 02 - Faz análise exploratória dos dados do SIM tratado
rmarkdown::render(
  here::here("r", "02_sim_analise.Rmd"),
  output_format = "html_document",
  output_dir = here::here("outputs"),
  output_file = 'sim_analise', 
  output_options = list(toc = TRUE,
                        number_sections = TRUE)
  )
rm(list = ls()) 

# 03 - Implementa modelos de regressão logística
# Unidade: cbo_4_agreg e grupo ocupacional
# Exporta modelos para "data" em formato parquet
source(here::here("r", "03_sim_modelo.R"))

# 04 - Faz análise dos modelos de regressão logística
rmarkdown::render(
  here::here("r", "04_sim_analise_modelo.Rmd"),
  output_format = "html_document",
  output_dir = here::here("outputs"),
  output_file = 'sim_analise_modelo', 
  output_options = list(toc = TRUE,
                        number_sections = TRUE)
)
rm(list = ls()) 

# 05 - Faz análise exploratória dos dados com mediação de dados externos
# Planilha enviada por Rogério Barbosa
# AVALIAR PERTINÊNCIA DA ANÁLISE
source(here::here("r", "05_sim_analise_mensal.R"))
rm(list = ls()) 


