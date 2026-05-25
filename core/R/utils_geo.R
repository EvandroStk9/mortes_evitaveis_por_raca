# core/R/utils_geo.R
# Utilitrios para harmonizao territorial e espacial

#' Harmoniza cdigos de municpio para 6 ou 7 dgitos
#' @param code cdigo do IBGE
#' @param target_digits 6 ou 7
normalize_muni_code <- function(code, target_digits = 7) {
  code <- as.character(code)
  if (target_digits == 6) {
    return(substr(code, 1, 6))
  } else {
    # Aqui poderia ter uma lgica para converter 6 -> 7 via lookup table
    return(code)
  }
}

#' Adiciona nomes de UF e Regio baseada no cdigo IBGE
add_geo_metadata <- function(data, code_col = "code_muni") {
  # Assume que o dado tem uma coluna com cdigo IBGE
  data %>%
    mutate(
      code_uf = substr(!!sym(code_col), 1, 2),
      nome_uf = case_when(
        code_uf == "11" ~ "Rondnia",
        code_uf == "12" ~ "Acre",
        code_uf == "13" ~ "Amazonas",
        code_uf == "14" ~ "Roraima",
        code_uf == "15" ~ "Par",
        code_uf == "16" ~ "Amap",
        code_uf == "17" ~ "Tocantins",
        code_uf == "21" ~ "Maranho",
        code_uf == "22" ~ "Piau",
        code_uf == "23" ~ "Cear",
        code_uf == "24" ~ "Rio Grande do Norte",
        code_uf == "25" ~ "Paraba",
        code_uf == "26" ~ "Pernambuco",
        code_uf == "27" ~ "Alagoas",
        code_uf == "28" ~ "Sergipe",
        code_uf == "29" ~ "Bahia",
        code_uf == "31" ~ "Minas Gerais",
        code_uf == "32" ~ "Esprito Santo",
        code_uf == "33" ~ "Rio de Janeiro",
        code_uf == "35" ~ "So Paulo",
        code_uf == "41" ~ "Paran",
        code_uf == "42" ~ "Santa Catarina",
        code_uf == "43" ~ "Rio Grande do Sul",
        code_uf == "50" ~ "Mato Grosso do Sul",
        code_uf == "51" ~ "Mato Grosso",
        code_uf == "52" ~ "Gois",
        code_uf == "53" ~ "Distrito Federal",
        TRUE ~ "Desconhecido"
      )
    )
}
