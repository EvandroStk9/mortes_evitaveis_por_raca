# tests/test_data_quality.R
library(pointblank)

#' Valida tabela Gold de Mortalidade
validate_gold_mortality <- function(data) {
  agent <- create_agent(tbl = data) %>%
    # Colunas essenciais
    col_exists(columns = vars(code_muni, raca_cor, obitos, taxa_mortalidade)) %>%
    # Valores positivos
    col_vals_gte(columns = vars(obitos, taxa_mortalidade), value = 0) %>%
    # Integridade de Raa/Cor
    col_vals_in_set(columns = vars(raca_cor), set = c("Branca", "Preta", "Parda", "Amarela", "Indgena", "Ignorado/NI")) %>%
    interrogate()
    
  return(agent)
}
