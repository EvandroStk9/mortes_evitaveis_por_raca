# core/R/standards_race.R
# Protocolo Institucional para Dados de Raa/Cor

#' Padronizao Categrica IBGE
#' Define os labels oficiais e a ordem dos fatores para visualizao
get_race_labels <- function() {
  c(
    "1" = "Branca",
    "2" = "Preta",
    "3" = "Amarela",
    "4" = "Parda",
    "5" = "Indgena",
    "9" = "Ignorado"
  )
}

#' Protocolo de Agregao para Anlise de Desigualdade
#' @description Conforme o Estatuto da Igualdade Racial e prticas do IBGE/IPEA
standardize_race_groups <- function(data, col = "racacor") {
  data %>%
    mutate(
      raca_cor_ibge = recode(as.character(!!sym(col)), !!!get_race_labels()),
      raca_cor_agreg = case_when(
        raca_cor_ibge %in% c("Preta", "Parda") ~ "Negra",
        raca_cor_ibge == "Branca" ~ "Branca",
        raca_cor_ibge == "Indgena" ~ "Indgena",
        raca_cor_ibge == "Amarela" ~ "Amarela",
        TRUE ~ "Ignorado/NI"
      ),
      # Fator ordenado para garantir que 'Branca' seja a categoria de referncia em modelos
      raca_cor_agreg = factor(raca_cor_agreg, levels = c("Branca", "Negra", "Indgena", "Amarela", "Ignorado/NI"))
    )
}

#' Clculo de Indicadores de Disparidade Racial
#' @param data_gold Dataframe agregado com taxas por raa
#' @param ref_group Grupo de referncia (default "Branca")
calculate_race_disparity <- function(data_gold, ref_group = "Branca") {
  
  # Calcula Rate Ratio (RR) e Rate Difference (RD)
  # RR = Taxa_Grupo / Taxa_Ref
  # RD = Taxa_Grupo - Taxa_Ref
  
  ref_taxa <- data_gold %>% 
    filter(raca_cor_agreg == ref_group) %>% 
    pull(taxa_mortalidade)
  
  data_gold %>%
    mutate(
      rate_ratio = taxa_mortalidade / ref_taxa,
      rate_difference = taxa_mortalidade - ref_taxa,
      disparidade_interpretacao = case_when(
        rate_ratio > 1.1 ~ paste0("Sobremortalidade em relao a ", ref_group),
        rate_ratio < 0.9 ~ paste0("Submortalidade em relao a ", ref_group),
        TRUE ~ "Equilbrio"
      )
    )
}

#' Protocolo para Dados Faltantes (Missing Data)
#' @description Define como lidar com a categoria 'Ignorado'
handle_race_missing <- function(data, method = c("exclude", "keep", "redistribute")) {
  method <- match.arg(method)
  
  if (method == "exclude") {
    return(data %>% filter(raca_cor_ibge != "Ignorado"))
  }
  
  if (method == "redistribute") {
    # Aqui entraria uma lgica de imputao ou redistribuio proporcional
    # til para quando o % de ignorados  alto e enviesa a taxa
    message("Aviso: Mtodo de redistribuio ainda no implementado.")
    return(data)
  }
  
  return(data)
}
