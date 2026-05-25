# core/R/utils_viz.R
# Motor de Visualização Institucional - CEBRAP

library(ggplot2)
library(scales)
library(ggtext)
library(showtext)

# Identidade Visual CEBRAP (Definida no core/setup.R)
# Cores para Raça/Cor padronizadas
get_cebrap_color_scale <- function() {
  scale_color_manual(
    values = c(
      "Branca"      = "#2874A6",
      "Negra"       = "#D4AC0D",
      "Indígena"    = "#1B4F72",
      "Amarela"     = "#7F8C8D",
      "Ignorado/NI" = "#ABB2B9"
    )
  )
}

#' Gráfico de Tendência com Foco em Desigualdade Racial
plot_indicador_raca <- function(data, titulo = "", eixo_y = "Taxa por 100k") {
  req_cols <- c("ano", "raca_cor_agreg", "taxa_mortalidade")
  if (!all(req_cols %in% names(data))) return(NULL)

  data %>%
    ggplot(aes(x = ano, y = taxa_mortalidade, color = raca_cor_agreg)) +
    geom_line(linewidth = 1.2, alpha = 0.8) +
    geom_point(size = 3) +
    get_cebrap_color_scale() +
    scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    scale_x_continuous(breaks = seq(min(data$ano), max(data$ano), by = 1)) +
    labs(
      title = titulo,
      subtitle = "Desagregação por Raça/Cor (Agregação Institucional)",
      x = "Ano de Ocorrência",
      y = eixo_y,
      color = "Grupo Racial"
    ) +
    tema_plataforma() # Tema definido no core/setup.R
}

#' Gráfico de Disparidade (Rate Ratio)
#' Compara a taxa de outros grupos em relação à categoria Branca
plot_disparidade_raca <- function(data, ref_group = "Branca") {
  # Lógica de cálculo de disparidade em tempo de execução para o gráfico
  data_ref <- data %>% 
    filter(raca_cor_agreg == ref_group) %>%
    select(ano, taxa_ref = taxa_mortalidade)
  
  data %>%
    left_join(data_ref, by = "ano") %>%
    mutate(rate_ratio = taxa_mortalidade / taxa_ref) %>%
    filter(raca_cor_agreg != ref_group) %>%
    ggplot(aes(x = ano, y = rate_ratio, fill = raca_cor_agreg)) +
    geom_col(position = "dodge") +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
    get_cebrap_color_scale() +
    labs(
      title = "Razão de Taxas (Rate Ratio)",
      subtitle = paste0("Referência (1.0): População ", ref_group),
      x = "Ano",
      y = "Vezes mais mortes",
      fill = "Grupo"
    ) +
    tema_plataforma()
}
