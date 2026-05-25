# core/R/utils_pop.R
# Utilitrios para busca de dados populacionais (IBGE/SIDRA)

#' Busca populao por UF, raa e sexo
get_pop_ibge <- function(years) {
  message("Buscando populao IBGE para os anos: ", paste(years, collapse = ", "))
  
  # Placeholder para simular dados de populao por UF e Raa_Cor_Agreg
  # Em um cenario real, usariamos sidrar::get_sidra()
  expand.grid(
    code_uf = c("11", "12", "13", "14", "15", "16", "17", "21", "22", "23", "24", "25", "26", "27", "28", "29", "31", "32", "33", "35", "41", "42", "43", "50", "51", "52", "53"),
    ano = years,
    raca_cor_agreg = c("Branca", "Negra", "Indgena", "Amarela", "Outros/Ignorado"),
    stringsAsFactors = FALSE
  ) %>%
    as_tibble() %>%
    mutate(populacao = 1000000) # Valor ficticio para teste
}
