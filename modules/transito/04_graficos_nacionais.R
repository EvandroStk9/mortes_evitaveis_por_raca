# =============================================================================
# 04_graficos_nacionais.R
# Graficos nacionais:
#   1. Linha - mortes totais no trafego (Brasil, 2000-2024)
#   2. Linha - mortes por 100 mil habitantes (Brasil, 2000-2024)
#   7. Heatmap mes x ano (sazonalidade)
#   8. Linha de media mensal com banda min-max
# =============================================================================

source(here::here("scripts", "00_setup.R"))

mortes_br_ano     <- arrow::read_parquet(file.path(dir_processados, "mortes_br_ano.parquet"))
mortes_br_ano_mes <- arrow::read_parquet(file.path(dir_processados, "mortes_br_ano_mes.parquet"))

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

# --- Grafico 1: mortes totais (linha) ---------------------------------------
g1 <- mortes_br_ano |>
  mutate(label = paste0(round(obitos / 1000, digits = 1), "k")) %>% 
  ggplot(aes(ano, obitos)) +
  geom_line(color = cores_maio$amarelo, linewidth = 1.2) +
  geom_point(color = cores_maio$amarelo, size = 2.5) +
  geom_text(aes(label = label),
            vjust = -1, family = "Roboto Bold Medio", size = 4.5) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ","),
                     breaks = seq(0, 100000, 5000),
                     limits = c(0, max(mortes_br_ano$obitos + 2000))) +
  scale_x_continuous(breaks = seq(2000, 2024, by = 1)) +
  labs(
    title    = "Mortes no trânsito no Brasil",
    subtitle = "Óbitos por acidente de trânsito",
    x        = NULL,
    y        = "Óbitos no ano\n",
    caption  = caption_padrao
  ) +
  tema +
  theme(
    axis.title.y = element_text(family = "Roboto", size = 14, color = "black")
  )

ggsave(file.path(dir_figuras, "01_mortes_nacionais.png"),
       g1, width = 9, height = 6, dpi = 150)

# --- Grafico 2: mortes por 100 mil hab. (linha) -----------------------------
g2 <- mortes_br_ano |>
  # filter(!is.na(taxa_100k)) |>
  ggplot(aes(ano, taxa_100k)) +
  geom_line(color = cores_maio$vermelho, linewidth = 1.2) +
  geom_point(color = cores_maio$vermelho, size = 2.5) +
  geom_text(aes(label = round(taxa_100k, digits = 1)),
            vjust = -1, family = "Roboto Bold Medio", size = 4.5) +
  scale_x_continuous(breaks = seq(2000, 2024, by = 1)) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ","),
                     breaks = seq(0, 100000, 5),
                     limits = c(0, max(mortes_br_ano$taxa_100k + 2))) +
  labs(
    title    = "Taxa de mortes no trânsito no Brasil",
    subtitle = "Óbitos por 100 mil habitantes",
    x        = NULL,
    y        = "Óbitos por 100 mil hab.\n",
    caption  = caption_padrao
  ) +
  tema +
  theme(
    axis.title.y = element_text(family = "Roboto", size = 14, color = "black")
  )

ggsave(file.path(dir_figuras, "02_taxa_nacional_100k.png"),
       g2, width = 9, height = 6, dpi = 150)

# --- Grafico 7: heatmap mes x ano -------------------------------------------
g7 <- mortes_br_ano_mes |>
  mutate(mes_lbl = factor(meses_pt[mes], levels = meses_pt)) |>
  mutate(ano = factor(ano, levels = 2000:2024)) |>
  ggplot(aes(mes_lbl, fct_rev(ano), fill = obitos)) +
  geom_tile(color = "white", linewidth = 0.4) +
  scale_fill_gradient(
    low      = "#FFF6CC",
    high     = cores_maio$vermelho,
    labels   = label_number(big.mark = ".", decimal.mark = ","),
    name     = "Óbitos no mes"
  ) +
  scale_y_discrete(expand = c(0, 0)) +
  scale_x_discrete(expand = c(0, 0)) +
  labs(
    title    = "Sazonalidade das mortes no trânsito",
    subtitle = "Cada célula = óbitos no mês/ano.<br>Tons mais <b><span style='color:#CE2827;'>escuros </span></b> indicam mais mortes enquanto tons mais <b><span style='color:#FCD4AB;'>claros </span></b> indicam menos mortes",
    x        = NULL,
    y        = NULL,
    caption  = caption_padrao
  ) +
  tema +
  theme(
    plot.subtitle = ggtext::element_markdown(family = "Roboto", size = 17, hjust = 0.5, 
                                             lineheight = 0.75),
    axis.text.x = element_text(family = "Roboto", size = 16, color = "black",
                               angle = 0, vjust = 1, hjust = 0.5),
    legend.title = element_text(family = "Roboto Bold", size = 13, color = "black"),
    panel.grid       = element_blank(),
    legend.key.width = unit(1.2, "cm"),
    legend.position  = "right"
  )

ggsave(file.path(dir_figuras, "07_heatmap_sazonalidade.png"),
       g7, width = 11, height = 7, dpi = 150)

# --- Grafico 8: media mensal com banda min-max ------------------------------
sazonalidade_resumo <- mortes_br_ano_mes |>
  group_by(mes) |>
  summarise(
    media = mean(obitos, na.rm = TRUE),
    minimo = min(obitos, na.rm = TRUE),
    maximo = max(obitos, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(mes_lbl = factor(meses_pt[mes], levels = meses_pt))

mes_pior  <- sazonalidade_resumo |> slice_max(media, n = 1) |> pull(mes_lbl)
mes_melhor <- sazonalidade_resumo |> slice_min(media, n = 1) |> pull(mes_lbl)

g8 <- sazonalidade_resumo |>
  ggplot(aes(x = mes_lbl, group = 1)) +
  geom_ribbon(aes(ymin = minimo, ymax = maximo),
              fill = cores_maio$amarelo, alpha = 0.35) +
  geom_line(aes(y = media), color = cores_maio$cinza_escuro, linewidth = 1.3) +
  geom_point(aes(y = media), color = cores_maio$cinza_escuro, size = 2.5) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ","),
                     limits = c(0, max(sazonalidade_resumo$maximo + 100))) +
  labs(
    title    = "Em quais meses o trânsito mata mais?",
    subtitle = paste0("Média mensal de óbitos\nMargem amarela mostra minimo e máximo do mês ao longo da série",
                      "\nEm média, o pico das mortes costuma ser em Dezembro"),
    x        = NULL,
    y        = "Obitos no mes",
    caption  = caption_padrao
  ) +
  tema +
  theme(
    axis.text.x = element_text(family = "Roboto", size = 16, color = "black",
                               angle = 0, vjust = 1, hjust = 0.5)
  )

ggsave(file.path(dir_figuras, "08_sazonalidade_resumo.png"),
       g8, width = 9, height = 6, dpi = 150)

# --- Tabela auxiliar --------------------------------------------------------
write_csv(sazonalidade_resumo,
          file.path(dir_tabelas, "sazonalidade_resumo.csv"))

message("Graficos nacionais salvos em ", dir_figuras)
