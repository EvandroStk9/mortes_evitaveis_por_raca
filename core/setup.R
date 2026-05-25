# core/setup.R
# Configuraes globais da plataforma

# Pacotes base
suppressPackageStartupMessages({
  library(tidyverse)
  library(arrow)
  library(here)
})

# Paleta Institucional (Pode ser expandida para cada mdulo)
paleta_cebrap <- list(
  primaria = "#1B4F72",
  secundaria = "#2874A6",
  destaque = "#D4AC0D",
  preto = "#1C2833",
  cinza = "#7F8C8D",
  branco = "#FDFEFE"
)

# Tema ggplot2 Global
tema_plataforma <- function() {
  theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", color = paleta_cebrap$primaria),
      plot.subtitle = element_text(color = paleta_cebrap$cinza),
      axis.title = element_text(color = paleta_cebrap$preto),
      legend.position = "bottom"
    )
}

theme_set(tema_plataforma())

# Utilitrios de Path
path_raw <- function(...) here::here("data", "raw", ...)
path_staging <- function(...) here::here("data", "staging", ...)
path_gold <- function(...) here::here("data", "gold", ...)

message("Core setup finalizado.")
