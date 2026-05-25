# core/R/utils_viz.R
# Motor de Visualização Institucional - CEBRAP (Versão Trimestral)

library(ggplot2)
library(scales)
library(ggtext)
library(showtext)

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

get_cebrap_fill_scale <- function() {
  scale_fill_manual(
    values = c(
      "Branca"      = "#2874A6",
      "Negra"       = "#D4AC0D",
      "Indígena"    = "#1B4F72",
      "Amarela"     = "#7F8C8D",
      "Ignorado/NI" = "#ABB2B9"
    )
  )
}

plot_disparidade_raca_trimestral <- function(data, ref_group = "Branca") {
  data_ref <- data %>% 
    filter(raca_cor_agreg == ref_group) %>%
    select(ano_trimestre, taxa_ref = taxa_mortalidade)
  
  # Se não houver dados do grupo de referência, não gera o gráfico
  if (nrow(data_ref) == 0) return(NULL)
  
  data %>%
    left_join(data_ref, by = "ano_trimestre") %>%
    mutate(rate_ratio = taxa_mortalidade / taxa_ref) %>%
    filter(raca_cor_agreg != ref_group) %>%
    ggplot(aes(x = ano_trimestre, y = rate_ratio, fill = raca_cor_agreg)) +
    geom_col(position = "dodge") +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
    get_cebrap_fill_scale() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(
      title = "Razão de Taxas Trimestral (Rate Ratio)",
      subtitle = paste0("Referência (1.0): População ", ref_group),
      x = "Trimestre",
      y = "Vezes mais mortes",
      fill = "Grupo Racial"
    ) +
    tema_plataforma()
}
