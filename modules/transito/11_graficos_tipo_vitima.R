# =============================================================================
# 11_graficos_tipo_vitima.R
# Quebra as mortes no transito (V01-V89) por tipo de vitima usando as
# subfaixas do CID-10:
#   V01-V09 Pedestres | V10-V19 Ciclistas | V20-V29 Motociclistas
#   V40-V59 Carro/caminhonete | V60-V79 Caminhao/onibus
#   V30-V39 + V80-V89 -> Outros (triciclos, off-road, nao especificados)
#
# Gera 3 graficos:
#   a) area empilhada (valores absolutos 2000-2024)
#   b) multi-linha (uma linha por categoria)
#   c) area empilhada em % (composicao ao longo do tempo)
# =============================================================================

source(here::here("scripts", "00_setup.R"))

# --- 1. Le todos os parquets brutos do SIM ----------------------------------
arquivos_sim <- list.files(
  dir_brutos,
  pattern    = "^sim_do_v_\\d{4}\\.parquet$",
  full.names = TRUE
)

sim_bruto <- arquivos_sim |>
  map(arrow::read_parquet) |>
  list_rbind()

# --- 2. Categoriza por tipo de vitima ---------------------------------------
mortes_cat <- sim_bruto |>
  mutate(v_num = as.integer(str_sub(causabas, 2, 3))) |>
  filter(
    str_starts(causabas, "V"),
    v_num >= 1, v_num <= 89   # transporte terrestre apenas
  ) |>
  mutate(
    categoria = case_when(
      v_num >= 1  & v_num <= 9  ~ "Pedestres",
      v_num >= 10 & v_num <= 19 ~ "Ciclistas",
      v_num >= 20 & v_num <= 29 ~ "Motociclistas",
      v_num >= 40 & v_num <= 59 ~ "Carro / caminhonete",
      v_num >= 60 & v_num <= 79 ~ "Caminhão / ônibus",
      TRUE                      ~ "Outros"
    )
  )

# --- 3. Agrega por ano e categoria ------------------------------------------
mortes_por_cat_ano <- mortes_cat |>
  count(ano, categoria, name = "obitos")

# Ordem para o stack: maiores no ano mais recente embaixo, "Outros" sempre no topo
ano_recente <- max(mortes_por_cat_ano$ano)

ordem_cat <- mortes_por_cat_ano |>
  filter(ano == ano_recente, categoria != "Outros") |>
  arrange(desc(obitos)) |>
  pull(categoria)
ordem_cat <- c(ordem_cat, "Outros")

dados_plot <- mortes_por_cat_ano |>
  mutate(categoria = factor(categoria, levels = ordem_cat))

# Salva tabela auxiliar
arrow::write_parquet(dados_plot,
                     file.path(dir_processados, "mortes_por_categoria_ano.parquet"))
write_csv(dados_plot,
          file.path(dir_tabelas, "mortes_por_categoria_ano.csv"))

# --- 4. Stats para subtitulos -----------------------------------------------
pct_categoria <- dados_plot |>
  group_by(ano) |>
  mutate(pct = obitos / sum(obitos)) |>
  ungroup()

pct_moto_2000 <- pct_categoria |>
  filter(ano == 2000, categoria == "Motociclistas") |> pull(pct)
pct_moto_atual <- pct_categoria |>
  filter(ano == ano_recente, categoria == "Motociclistas") |> pull(pct)

pct_pedestre_2000 <- pct_categoria |>
  filter(ano == 2000, categoria == "Pedestres") |> pull(pct)
pct_pedestre_atual <- pct_categoria |>
  filter(ano == ano_recente, categoria == "Pedestres") |> pull(pct)

# --- 5. Fonte e tema --------------------------------------------------------
sysfonts::font_add_google("Roboto", "Roboto", bold.wt = 900, regular.wt = 300)
sysfonts::font_add_google("Roboto", "Roboto Bold", regular.wt = 900)
sysfonts::font_add_google("Roboto", "Roboto Bold Medio", regular.wt = 400)
showtext::showtext_auto()

tema <- theme_minimal(base_size = 11) +
  theme(
    plot.title.position = "plot",
    plot.title    = element_text(face = "bold", family = "Roboto", size = 22, hjust = 0.5),
    plot.subtitle = element_text(family = "Roboto", size = 17, hjust = 0.5,
                                 lineheight = 0.75),
    legend.position = "top",
    legend.text  = element_text(family = "Roboto", size = 13),
    legend.title = element_blank(),
    axis.text.y = element_text(family = "Roboto", size = 13, color = "black"),
    axis.text.x = element_text(family = "Roboto", size = 13, color = "black",
                               angle = 90, hjust = 1, vjust = 0.5),
    axis.title  = element_blank(),
    plot.caption = element_text(family = "Roboto", size = 14),
    panel.grid.minor = element_blank()
  )

# Paleta - destaca motociclistas em vermelho (o "vilao") e usa cinza para Outros
cores_cat <- c(
  "Motociclistas"       = "firebrick3",   # vermelho (foco)
  "Pedestres"           = "orange2",   # laranja (vulneravel)
  "Carro / caminhonete" = "darkblue",   # azul
  "Caminhão / ônibus"   = "purple",   # roxo
  "Ciclistas"           = "forestgreen",   # verde (bicicleta)
  "Outros"              = "#999999"    # cinza
)

# --- 6a. Area empilhada (absolutos) -----------------------------------------
g_area <- dados_plot |>
  ggplot(aes(ano, obitos, fill = categoria)) +
  geom_area(alpha = 0.95) +
  scale_fill_manual(values = cores_cat) +
  scale_x_continuous(breaks = seq(2000, ano_recente, by = 2),
                     expand = c(0, 0)) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ","),
                     expand = expansion(mult = c(0, 0.02))) +
  labs(
    title    = "Quem morre no trânsito brasileiro",
    subtitle = sprintf(
      "Brasil, 2000-%d. Os motociclistas saltaram de %s para %s do total.",
      ano_recente,
      label_percent(accuracy = 0.1, decimal.mark = ",")(pct_moto_2000),
      label_percent(accuracy = 0.1, decimal.mark = ",")(pct_moto_atual)
    ),
    caption  = caption_padrao
  ) +
  tema

ggsave(file.path(dir_figuras, "11_tipo_vitima_area.png"),
       g_area, width = 11, height = 7, dpi = 150)

# --- 6b. Multi-linha --------------------------------------------------------
g_linhas <- dados_plot |>
  ggplot(aes(ano, obitos, color = categoria, group = categoria)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 1.5) +
  scale_color_manual(values = cores_cat) +
  scale_x_continuous(breaks = seq(2000, ano_recente, by = 2)) +
  scale_y_continuous(labels = label_number(big.mark = ".", decimal.mark = ","),
                     limits = c(0, NA),
                     breaks = seq(0, 100000, 2500)) +
  labs(
    title    = "Número de óbitos por tipo de vítima",
    subtitle = "Classificações de tipo de vítima feitas pelo CID-10",
    caption  = caption_padrao
  ) +
  tema

ggsave(file.path(dir_figuras, "11_tipo_vitima_linhas.png"),
       g_linhas, width = 11, height = 7, dpi = 150)

# --- 6c. % empilhado (composicao) -------------------------------------------
g_pct <- pct_categoria |>
  ggplot(aes(ano, pct, fill = categoria)) +
  geom_area(alpha = 0.95) +
  scale_fill_manual(values = cores_cat) +
  scale_x_continuous(breaks = seq(2000, ano_recente, by = 2),
                     expand = c(0, 0)) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","),
                     expand = c(0, 0)) +
  labs(
    title    = "Como mudou a composição das mortes no trânsito",
    subtitle = "Participação de cada tipo de vítima no total anual",
    caption  = caption_padrao
  ) +
  tema

ggsave(file.path(dir_figuras, "11_tipo_vitima_pct.png"),
       g_pct, width = 11, height = 7, dpi = 150)

# --- 7. Mensagem resumo -----------------------------------------------------
message(sprintf(
  "Tipo de vitima: %d -> Motos %s | Pedestres %s\n%d -> Motos %s | Pedestres %s",
  2000,
  label_percent(accuracy = 0.1, decimal.mark = ",")(pct_moto_2000),
  label_percent(accuracy = 0.1, decimal.mark = ",")(pct_pedestre_2000),
  ano_recente,
  label_percent(accuracy = 0.1, decimal.mark = ",")(pct_moto_atual),
  label_percent(accuracy = 0.1, decimal.mark = ",")(pct_pedestre_atual)
))
message("3 graficos por tipo de vitima salvos em ", dir_figuras)
