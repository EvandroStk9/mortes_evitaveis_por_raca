# =============================================================================
# 00_setup.R
# Carrega pacotes, define paleta de cores e tema visual do Maio Amarelo.
# Rode este script no início de cada sessão (os demais já dão source nele).
# =============================================================================

# --- Instalacao de pacotes (apenas se necessario) ----------------------------
pacotes_cran <- c(
  "tidyverse", "here", "sidrar", "geobr", "sf", "arrow",
  "scales", "lubridate", "janitor", "remotes", "ggtext", "patchwork"
)

instalar_se_faltando <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}
invisible(lapply(pacotes_cran, instalar_se_faltando))

# microdatasus vive no GitHub (rfsaldanha/microdatasus)
if (!requireNamespace("microdatasus", quietly = TRUE)) {
  remotes::install_github("rfsaldanha/microdatasus")
}

# --- Carregamento dos pacotes -----------------------------------------------
suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
  library(microdatasus)
  library(sidrar)
  library(geobr)
  library(sf)
  library(arrow)
  library(scales)
  library(lubridate)
  library(janitor)
  library(ggtext)
  library(patchwork)
})

# --- Paleta Maio Amarelo ----------------------------------------------------
cores_maio <- list(
  amarelo        = "#FFCF00",
  amarelo_escuro = "#E8B400",
  cinza_escuro   = "grey10",
  cinza_medio    = "grey40",
  cinza_claro    = "grey80",
  vermelho       = "firebrick3"
)

# # --- Tema base para os graficos ---------------------------------------------
# tema_maio <- function(base_size = 13) {
#   theme_minimal(base_size = base_size) +
#     theme(
#       plot.background      = element_rect(fill = cores_maio$fundo, color = NA),
#       panel.background     = element_rect(fill = cores_maio$fundo, color = NA),
#       panel.grid.minor     = element_blank(),
#       panel.grid.major     = element_line(color = cores_maio$cinza_claro, linewidth = 0.3),
#       plot.title           = element_text(face = "bold", size = base_size + 4,
#                                           color = cores_maio$cinza_escuro),
#       plot.subtitle        = element_text(size = base_size, color = cores_maio$cinza_medio,
#                                           margin = margin(b = 10)),
#       plot.caption         = element_text(size = base_size - 3, color = cores_maio$cinza_medio,
#                                           hjust = 0),
#       axis.title           = element_text(color = cores_maio$cinza_escuro),
#       axis.text            = element_text(color = cores_maio$cinza_escuro),
#       legend.position      = "bottom",
#       legend.title         = element_text(face = "bold"),
#       strip.text           = element_text(face = "bold", color = cores_maio$cinza_escuro)
#     )
# }
# 
# # Aplica o tema como default em todos os ggplots
# theme_set(tema_maio())

# --- Caption padrao para redes sociais --------------------------------------
caption_padrao <- "\nFonte: SIM/DATASUS e IBGE\nFeito por: Artur Vidaurre de Almeida"

# --- Diretorios (atalhos) ---------------------------------------------------
dir_brutos       <- here::here("dados", "brutos")
dir_processados  <- here::here("dados", "processados")
dir_figuras      <- here::here("outputs", "figuras")
dir_tabelas      <- here::here("outputs", "tabelas")

# Cria diretorios se nao existirem
for (d in c(dir_brutos, dir_processados, dir_figuras, dir_tabelas)) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE)
}

message("Setup concluido. Pacotes carregados e tema aplicado.")
