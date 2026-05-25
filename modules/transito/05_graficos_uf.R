# =============================================================================
# 05_graficos_uf.R
# Graficos por UF:
#   3. Mapa coropletico - taxa de mortes/100k por UF no ano mais recente
#   4. Painel facet_wrap - evolucao da taxa por UF, 2000-2024
# =============================================================================

source(here::here("scripts", "00_setup.R"))

mortes_uf_ano <- arrow::read_parquet(file.path(dir_processados, "mortes_uf_ano.parquet"))

ano_recente <- max(mortes_uf_ano$ano, na.rm = TRUE)

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

# --- Carrega shapefile dos estados via geobr, removendo ilhas ---------------
# A logica de "manter so o maior poligono por UF" elimina ilhas (Marajo,
# Fernando de Noronha, etc.) que poluem visualmente o mapa.
brasil_uf <- geobr::read_state() |>
  select(abbrev_state) |>
  sf::st_cast("POLYGON") |>
  mutate(area = sf::st_area(geom)) |>
  group_by(abbrev_state) |>
  slice_max(area, n = 1, with_ties = FALSE) |>
  ungroup() |>
  select(-area)

# --- Grafico 3: Mapa por UF (ano mais recente) ------------------------------
mapa_dados <- brasil_uf |>
  left_join(
    mortes_uf_ano |>
      filter(ano == ano_recente) |>
      select(sigla_uf, taxa_100k),
    by = c("abbrev_state" = "sigla_uf")
  )

g3 <- mapa_dados |>
  ggplot() +
  geom_sf(aes(fill = taxa_100k), color = "white", linewidth = 0.25) +
  geom_sf_text(
    aes(label = round(taxa_100k, digits = 1)),
    size = 2.8, color = cores_maio$cinza_escuro, family = "Roboto Bold Medio"
  ) +
  scale_fill_gradient(
    low    = "#FFF6CC",
    high   = cores_maio$vermelho,
    name   = "Óbitos\npor 100 mil hab.",
    labels = label_number(decimal.mark = ",", accuracy = 0.1)
  ) +
  labs(
    title    = paste0("Mortes no trânsito por estado em ", ano_recente),
    subtitle = "Óbitos por 100 mil habitantes",
    caption  = caption_padrao
  ) +
  tema +
  theme(
    legend.position = "right",
    axis.title = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    panel.grid = element_blank(),
    legend.text = element_text(family = "Roboto", size = 15, color = "black"),
    legend.title = element_text(family = "Roboto Bold", size = 15, color = "black", lineheight = 0.75),
    plot.caption.position = "panel",
    plot.caption = element_text(hjust = 0)
  )


ggsave(file.path(dir_figuras, "03_mapa_uf_taxa.png"),
       g3, width = 8, height = 5, dpi = 150)

# --- Grafico 4: facet_wrap - evolucao por UF --------------------------------
ordem_ufs <- mortes_uf_ano |>
  filter(ano == max(ano)) %>% 
  arrange(desc(taxa_100k)) %>% 
  pull(sigla_uf)

dados_facet <- mortes_uf_ano |>
  filter(!is.na(taxa_100k), !is.na(sigla_uf)) |>
  mutate(sigla_uf = factor(sigla_uf, levels = ordem_ufs))

g4 <- dados_facet |>
  ggplot(aes(ano, taxa_100k)) +
  geom_line(color = cores_maio$amarelo_escuro, linewidth = 1) +
  geom_point(color = cores_maio$amarelo_escuro, size = 0.7) +
  facet_wrap(~ sigla_uf, ncol = 9) +
  scale_x_continuous(breaks = c(2000, 2010, 2020)) +
  scale_y_continuous(labels = label_number(decimal.mark = ",", accuracy = 1),
                     limits = c(0, max(dados_facet$taxa_100k + 2)),
                     breaks = seq(0, 100, 10)) +
  labs(
    title    = "Evolução da taxa de mortes no trânsito por estado",
    subtitle = paste0("Óbitos por 100 mil habitantes\nEstados ordenados pela taxa de ", ano_recente),
    x        = NULL,
    y        = "Mortes por 100 mil hab.\n",
    caption  = caption_padrao
  ) +
  tema +
  theme(
    axis.text  = element_text(size = 8),
    axis.title.y = element_text(family = "Roboto", size = 14, color = "black")
  ) 

ggsave(file.path(dir_figuras, "04_facet_uf_taxa.png"),
       g4, width = 11, height = 7, dpi = 150)

# --- Tabela auxiliar --------------------------------------------------------
ranking_uf_recente <- mortes_uf_ano |>
  filter(ano == ano_recente) |>
  arrange(desc(taxa_100k)) |>
  mutate(posicao = row_number()) |>
  select(posicao, sigla_uf, nome_uf, obitos, populacao, taxa_100k)

write_csv(ranking_uf_recente,
          file.path(dir_tabelas, paste0("ranking_uf_", ano_recente, ".csv")))

message("Graficos por UF salvos em ", dir_figuras)
