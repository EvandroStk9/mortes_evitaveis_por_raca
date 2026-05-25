# core/R/utils_viz.R
# Funções de visualização padronizadas (Fidelidade aos originais)

library(ggplot2)
library(scales)
library(ggtext)
library(showtext)

# Configuração de Fontes
# Tenta adicionar as fontes roboto
try({
  sysfonts::font_add_google("Roboto", "Roboto")
  showtext_auto()
}, silent = TRUE)

# Cores do Maio Amarelo (Preservadas)
cores_maio <- list(
  amarelo        = "#FFCF00",
  amarelo_escuro = "#E8B400",
  cinza_escuro   = "grey10",
  cinza_medio    = "grey40",
  cinza_claro    = "grey80",
  vermelho       = "firebrick3"
)

# Tema Original Refinado
tema_original <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold", size = 20, hjust = 0.5),
      plot.subtitle = element_text(size = 15, hjust = 0.5, lineheight = 0.75),
      legend.position = "top",
      strip.text = element_text(face = "bold", size = 14),
      axis.text.y = element_text(size = 12, color = "black"),
      axis.text.x = element_text(size = 12, color = "black"),
      axis.title = element_text(size = 12),
      plot.caption = element_text(size = 10, hjust = 0),
      panel.grid.minor = element_blank()
    )
}

#' Plot de Tendência Nacional (Linha)
plot_tendencia_nacional <- function(data, col_y = "obitos", titulo = "", subtitulo = "", cor = cores_maio$amarelo) {
  data %>%
    ggplot(aes(x = ano, y = !!sym(col_y))) +
    geom_line(color = cor, linewidth = 1.2) +
    geom_point(color = cor, size = 2.5) +
    scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    scale_x_continuous(breaks = seq(min(data$ano), max(data$ano), by = 2)) +
    labs(title = titulo, subtitle = subtitulo, x = NULL, y = NULL) +
    tema_original()
}

#' Plot de Heatmap de Sazonalidade
plot_heatmap_sazonalidade <- function(data) {
  meses_pt <- c("Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez")
  
  data %>%
    mutate(mes_lbl = factor(meses_pt[mes], levels = meses_pt)) %>%
    ggplot(aes(x = mes_lbl, y = factor(ano), fill = obitos)) +
    geom_tile(color = "white") +
    scale_fill_gradient(low = "#FFF6CC", high = cores_maio$vermelho, labels = label_number()) +
    labs(title = "Sazonalidade das Mortes", x = NULL, y = NULL, fill = "Óbitos") +
    tema_original() +
    theme(panel.grid = element_blank())
}
