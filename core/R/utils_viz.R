# core/R/utils_viz.R
# Funções de visualização padronizadas (Fidelidade aos originais)

library(ggplot2)
library(scales)
library(ggtext)
library(showtext)
library(ggthemes)

# Configuração de Fontes (UTF-8 garantido)
try({
  sysfonts::font_add_google("Roboto", "Roboto")
  showtext_auto()
}, silent = TRUE)

# Cores Institucionais
cores_maio <- list(
  amarelo        = "#FFCF00",
  amarelo_escuro = "#E8B400",
  cinza_escuro   = "grey10",
  cinza_medio    = "grey40",
  cinza_claro    = "grey80",
  vermelho       = "firebrick3"
)

# Tema Original Maio Amarelo
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

# Tema Original COVID (Baseado no FiveThirtyEight)
tema_covid <- function(base_size = 14) {
  theme_fivethirtyeight(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5),
      legend.position = "bottom",
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    )
}

# --- GRÁFICOS TRÂNSITO ---

plot_tendencia_nacional <- function(data, col_y = "obitos", titulo = "", subtitulo = "", cor = cores_maio$amarelo) {
  data %>%
    ggplot(aes(x = ano, y = !!sym(col_y))) +
    geom_line(color = cor, linewidth = 1.2) +
    geom_point(color = cor, size = 2.5) +
    scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ",")) +
    scale_x_continuous(breaks = seq(min(data$ano, na.rm=T), max(data$ano, na.rm=T), by = 2)) +
    labs(title = titulo, subtitle = subtitulo, x = NULL, y = NULL) +
    tema_original()
}

plot_heatmap_sazonalidade <- function(data) {
  meses_pt <- c("Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez")
  
  data %>%
    mutate(mes_lbl = factor(meses_pt[mes], levels = meses_pt)) %>%
    ggplot(aes(x = mes_lbl, y = factor(ano), fill = obitos)) +
    geom_tile(color = "white") +
    scale_fill_gradient(low = "#FFF6CC", high = cores_maio$vermelho, labels = label_number(big.mark = ".", decimal.mark = ",")) +
    labs(title = "Sazonalidade das Mortes", x = NULL, y = NULL, fill = "Óbitos") +
    tema_original() +
    theme(panel.grid = element_blank())
}

# --- GRÁFICOS COVID ---

plot_covid_raca_sexo <- function(data) {
  data %>%
    ggplot(aes(x = obitos, y = fct_reorder(raca_cor, obitos), fill = sexo)) +
    geom_col(colour = "black") +
    labs(title = "Óbitos por COVID-19 - PEA",
         subtitle = "Distribuição por Raça/Cor e Sexo",
         x = "Número de Óbitos",
         y = NULL) +
    tema_covid()
}

plot_covid_ocupacao <- function(data) {
  # Reprodução do gráfico de dispersão do relatório
  data %>%
    ggplot(aes(x = obitos_covid, y = obitos_covid_cada_100_grupo, size = obitos_total)) +
    geom_point(alpha = 0.5, color = "steelblue") +
    scale_size(range = c(2, 20)) +
    scale_y_continuous(labels = function(x) paste0(x, "%")) +
    labs(title = "Mortalidade por Ocupação",
         subtitle = "Círculos representam o total de óbitos no grupo",
         x = "N° óbitos COVID-19",
         y = "% óbitos COVID-19 no grupo") +
    tema_covid() +
    theme(legend.position = "none")
}
