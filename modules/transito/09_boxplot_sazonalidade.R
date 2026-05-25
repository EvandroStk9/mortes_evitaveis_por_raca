# =============================================================================
# 09_boxplot_sazonalidade.R
# Boxplot da distribuicao mensal de mortes no transito (Brasil, 2000-2024).
# Cada caixa representa as 24 observacoes anuais daquele mes.
# Pontos sobrepostos = anos individuais (jitter horizontal).
# =============================================================================

source(here::here("scripts", "00_setup.R"))

mortes_br_ano_mes <- arrow::read_parquet(
  file.path(dir_processados, "mortes_br_ano_mes.parquet")
)

meses_pt <- c("Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
              "Jul", "Ago", "Set", "Out", "Nov", "Dez")

# Fonte plot
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
# --- Preparacao dos dados ---------------------------------------------------
dados_box <- mortes_br_ano_mes |>
  mutate(mes_lbl = factor(meses_pt[mes], levels = meses_pt))

# Destaca pior e melhor mes pela mediana, para citar no subtitulo
medianas <- dados_box |>
  group_by(mes_lbl) |>
  summarise(mediana = median(obitos), .groups = "drop")

mes_pior   <- medianas |> slice_max(mediana, n = 1) |> pull(mes_lbl)
mes_melhor <- medianas |> slice_min(mediana, n = 1) |> pull(mes_lbl)

# --- Boxplot ----------------------------------------------------------------
g <- dados_box |>
  ggplot(aes(mes_lbl, obitos)) +
  geom_boxplot(
    fill        = cores_maio$amarelo,
    color       = cores_maio$cinza_escuro,
    width       = 0.55,
    outlier.shape = NA,
    linewidth   = 0.5
  ) +
  geom_jitter(
    width  = 0.15,
    alpha  = 0.45,
    size   = 1.8,
    color  = cores_maio$cinza_escuro
  ) +
  scale_y_continuous(
    labels = label_number(big.mark = ".", decimal.mark = ","),
    breaks = scales::pretty_breaks(n = 6),
    limits = c(0, max(dados_box$obitos + 100))
  ) +
  labs(
    title    = "Sazonalidade das mortes de trânsito",
    subtitle = paste0(
      "Distribuição de óbitos mensais no Brasi"
    ),
    caption  = caption_padrao
  ) +
  tema +
  theme(
    axis.text.x = element_text(family = "Roboto", size = 16, color = "black",
                               angle = 0, vjust = 1, hjust = 0.5)
  )

ggsave(
  file.path(dir_figuras, "09_boxplot_sazonalidade.png"),
  g, width = 9, height = 6, dpi = 150
)

message("Boxplot de sazonalidade salvo em ",
        file.path(dir_figuras, "09_boxplot_sazonalidade.png"))
