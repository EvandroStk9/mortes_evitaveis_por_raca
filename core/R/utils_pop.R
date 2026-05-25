# core/R/utils_pop.R
# Utilitrios para busca de dados populacionais (IBGE/SIDRA)

#' Busca populao por municpio, raa e sexo (Censo 2022 ou Estimativas)
#' @param years anos desejados
get_pop_ibge <- function(years) {
  # Placeholder para busca via sidrar
  # Tabela 9514 (Censo 2022) ou 6579 (Estimativas anuais)
  message("Buscando populao IBGE para os anos: ", paste(years, collapse = ", "))
  
  # Exemplo de estrutura de retorno esperada
  # No mundo real, usaramos sidrar::get_sidra()
  # Por enquanto, criaremos um dataset vazio tipado
  tibble(
    code_muni = character(),
    ano = integer(),
    raca_cor = character(),
    populacao = numeric()
  )
}

#' Ajusta populao para anos intercensitrios (Interpolação)
interpolate_pop <- function(pop_data) {
  # Lgica para preencher anos entre censos
  pop_data
}
