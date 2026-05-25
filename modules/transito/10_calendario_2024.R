# =============================================================================
# 10_calendario_2024.R
# Heatmap tipo "calendario" das mortes diarias no transito em 2024.
# Cada celula = um dia do ano. Colunas = meses. Linhas = dias do mes.
# A base mensal exportada nao tem granularidade diaria, entao carregamos
# direto o parquet bruto do SIM de 2024.
# =============================================================================

source(here::here("scripts", "00_setup.R"))

ano_alvo <- 2024

# --- Le SIM bruto e agrega por dia ------------------------------------------
sim_ano <- arrow::read_parquet(
  file.path(dir_brutos, paste0("sim_do_v_", ano_alvo, ".parquet"))
)

mortes_dia <- sim_ano |>
  mutate(
    data_obito = lubridate::dmy(data_obito_raw),
    v_num      = as.integer(str_sub(causabas, 2, 3))
  ) |>
  # Mesmo filtro do 03_limpeza.R: so transporte terrestre (V01-V89)
  filter(
    !is.na(data_obito),
    lubridate::year(data_obito) == ano_alvo,
    str_starts(causabas, "V"),
    v_num >= 1, v_num <= 89
  ) |>
  mutate(
    dia = lubridate::day(data_obito),
    mes = lubridate::month(data_obito)
  ) |>
  count(mes, dia, name = "obitos")

meses_pt <- c("Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
              "Jul", "Ago", "Set", "Out", "Nov", "Dez")

# Dia mais letal (para citar no subtitulo)
dia_pior_row <- mortes_dia |> slice_max(obitos, n = 1)
dia_pior_str <- sprintf("%02d/%02d", dia_pior_row$dia, dia_pior_row$mes)

# Fonte
sysfonts::font_add_google("Roboto", "Roboto", bold.wt = 900, regular.wt = 300)
sysfonts::font_add_google("Roboto", "Roboto Bold", regular.wt = 900)
sysfonts::font_add_google("Roboto", "Roboto Bold Medio", regular.wt = 400)
showtext::showtext_auto()

# Define questões estéticas
tema <- theme_minimal(base_size = 11) +
  theme(
    plot.title.position = "plot",
    plot.title = element_text(face = "bold", family = "Roboto", size = 22, hjust = 0.5),
    plot.subtitle = element_text(family = "Roboto", size = 17, hjust = 0.5,
                                 lineheight = 0.75),
    legend.position = "top",
    strip.text = element_text(face = "bold", family = "Roboto", size = 16,
                              vjust = 0, lineheight = 0.65),
    axis.text.y = element_text(family = "Roboto", size = 14, color = "black"),
    axis.text.x = element_text(family = "Roboto", size = 14, color = "black",
                               angle = 90, hjust = 1, vjust = 0.5),
    axis.title = element_blank(),
    plot.caption = element_text(family = "Roboto", size = 14),
    legend.text = element_text(family = "Roboto", size = 15),
    panel.grid.minor = element_blank()
  )

# --- Heatmap ----------------------------------------------------------------
g <- mortes_dia |>
  mutate(
    mes_lbl = factor(meses_pt[mes], levels = meses_pt),
    dia     = factor(dia, levels = 1:31)
  ) |>
  ggplot(aes(dia, fct_rev(mes_lbl), fill = obitos)) +
  geom_tile(color = "white", linewidth = 0.4) +
  scale_fill_gradient(
    low    = "#FFF6CC",
    high   = cores_maio$vermelho,
    name   = "Óbitos no dia",
    labels = label_number(decimal.mark = ",", accuracy = 1)
  ) +
  geom_text(aes(label = obitos),
            family = "Roboto Bold Medio") +
  scale_y_discrete(expand = c(0, 0)) +
  scale_x_discrete(expand = c(0, 0)) +
  labs(
    title    = paste0("Calendário das mortes no trânsito - ", ano_alvo),
    subtitle = paste0(
      "Cada célula = óbitos no dia/mês<br>",
      "Tons mais <b><span style='color:#CE2827;'>escuros </span></b> indicam mais mortes enquanto tons mais ",
      "<b><span style='color:#FCD4AB;'>claros </span></b> indicam menos mortes<br>",
      "Dia mais letal = ", dia_pior_str
    ),
    caption  = caption_padrao
  ) +
  tema +
  coord_equal() +
  theme(
    plot.subtitle = ggtext::element_markdown(family = "Roboto", size = 17, hjust = 0.5,
                                             lineheight = 0.75),
    axis.text.y = element_text(family = "Roboto", size = 16, color = "black"),
    axis.text.x = element_text(family = "Roboto", size = 16, color = "black",
                               angle = 0, vjust = 1, hjust = 0.5),
    legend.title = element_text(family = "Roboto Bold", size = 13, color = "black"),
    panel.grid       = element_blank(),
    legend.key.width = unit(1.2, "cm"),
    legend.position  = "right"
  )

ggsave(
  file.path(dir_figuras, paste0("10_calendario_", ano_alvo, ".png")),
  g, width = 11, height = 7, dpi = 150
)

# --- Estatisticas auxiliares ------------------------------------------------
total_ano  <- sum(mortes_dia$obitos)
media_dia  <- round(mean(mortes_dia$obitos), 1)

message(sprintf(
  "Calendario %d salvo. Total: %s obitos | Media diaria: %s | Pior dia: %s (%s mortes)",
  ano_alvo,
  format(total_ano, big.mark = "."),
  format(media_dia, decimal.mark = ","),
  dia_pior_str, dia_pior_row$obitos
))
