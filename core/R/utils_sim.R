# core/R/utils_sim.R
# Utilitrios para o Sistema de Informao sobre Mortalidade (SIM)

#' Padroniza categorias de Raa/Cor seguindo o IBGE
#' @param data dataframe com a coluna RACACOR
#' @return dataframe com colunas raca_cor padronizada
standardize_race <- function(data) {
  data %>%
    mutate(
      raca_cor = case_when(
        racacor == 1 ~ "Branca",
        racacor == 2 ~ "Preta",
        racacor == 3 ~ "Amarela",
        racacor == 4 ~ "Parda",
        racacor == 5 ~ "Indgena",
        TRUE ~ "Ignorado/NI"
      ),
      # Agregao comum em estudos de desigualdade
      raca_cor_agreg = case_when(
        raca_cor %in% c("Preta", "Parda") ~ "Negra",
        raca_cor == "Branca" ~ "Branca",
        TRUE ~ "Outros/Ignorado"
      )
    )
}

#' Calcula Taxas de Mortalidade
#' @param obitos nmero de bitos
#' @param populacao populao de referncia
#' @param scale fator de escala (default 100.000)
calculate_mortality_rate <- function(obitos, populacao, scale = 100000) {
  (obitos / populacao) * scale
}

#' Wrapper para download do microdatasus com tratamento inicial
fetch_sim_raw <- function(years, causa = NULL) {
  # Aqui entraria a lgica do microdatasus::fetch_datasus
  # Por enquanto um placeholder para o pipeline
  message("Buscando dados SIM para anos: ", paste(years, collapse = ", "))
  return(NULL)
}
