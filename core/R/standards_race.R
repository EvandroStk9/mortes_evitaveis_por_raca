# core/R/standards_race.R
# Protocolo Institucional para Dados de Raça/Cor

#' Padronização Categórica IBGE
#' Define os labels oficiais e a ordem dos fatores para visualização
get_race_labels <- function() {
  c(
    "1" = "Branca",
    "2" = "Preta",
    "3" = "Amarela",
    "4" = "Parda",
    "5" = "Indígena",
    "9" = "Ignorado"
  )
}

#' Protocolo de Agregação para Análise de Desigualdade
#' @description Conforme o Estatuto da Igualdade Racial e práticas do IBGE/IPEA
standardize_race_groups <- function(data, col = "racacor") {
  data %>%
    mutate(
      raca_cor_ibge = recode(as.character(!!sym(col)), !!!get_race_labels()),
      raca_cor_agreg = case_when(
        raca_cor_ibge %in% c("Preta", "Parda") ~ "Negra",
        raca_cor_ibge == "Branca" ~ "Branca",
        raca_cor_ibge == "Indígena" ~ "Indígena",
        raca_cor_ibge == "Amarela" ~ "Amarela",
        TRUE ~ "Ignorado/NI"
      ),
      # Fator ordenado para garantir que 'Branca' seja a categoria de referência
      raca_cor_agreg = factor(raca_cor_agreg, levels = c("Branca", "Negra", "Indígena", "Amarela", "Ignorado/NI"))
    )
}

#' Cálculo de Indicadores de Disparidade Racial
#' @param data_gold Dataframe agregado com taxas por raça
#' @param ref_group Grupo de referência (default "Branca")
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
        rate_ratio > 1.1 ~ paste0("Sobremortalidade em relação a ", ref_group),
        rate_ratio < 0.9 ~ paste0("Submortalidade em relação a ", ref_group),
        TRUE ~ "Equilíbrio"
      )
    )
}
