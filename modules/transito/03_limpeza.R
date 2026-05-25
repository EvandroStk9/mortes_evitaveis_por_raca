# =============================================================================
# 03_limpeza.R
# Le os parquets do SIM (um por ano), consolida, enriquece com codigo de UF
# e mes, junta com populacao da SIDRA tabela 7358 (via 02_download_pop.R) e
# gera bases agregadas prontas para os graficos. Exporta a base final em
# parquet e CSV.
#
# Analises por municipio foram descartadas - todas as agregacoes sao em
# nivel Brasil ou UF.
# =============================================================================

source(here::here("scripts", "00_setup.R"))

# --- 1. Leitura e consolidacao dos arquivos do SIM --------------------------
arquivos_sim <- list.files(
  dir_brutos,
  pattern    = "^sim_do_v_\\d{4}\\.parquet$",
  full.names = TRUE
)

if (length(arquivos_sim) == 0) {
  stop("Nenhum arquivo do SIM encontrado em dados/brutos/. ",
       "Rode antes 01_download_sim.R")
}

message("Lendo ", length(arquivos_sim), " arquivos do SIM...")

sim_bruto <- arquivos_sim |>
  map(arrow::read_parquet) |>
  list_rbind()

message("Total de obitos por acidente de transporte (V01-V99): ",
        format(nrow(sim_bruto), big.mark = "."))

# --- 2. Limpeza / enriquecimento --------------------------------------------
# DTOBITO no SIM vem em DDMMAAAA (string). Convertemos para data.
# Codigo do municipio so usado aqui para derivar o codigo da UF (2 primeiros
# digitos). Nao mantemos granularidade municipal.
mortes <- sim_bruto |>
  mutate(
    data_obito = lubridate::dmy(data_obito_raw),
    mes        = lubridate::month(data_obito),
    cod_uf     = substr(str_pad(cod_mun_ocor, 6, side = "left", pad = "0"), 1, 2),
    # Extrai o numero do CID V (ex: "V234" -> 23) para filtrar V01-V89
    v_num      = as.integer(str_sub(causabas, 2, 3))
  ) |>
  # Restringe ao transporte terrestre (V01-V89), que e o foco do Maio Amarelo.
  # Exclui V90-V94 (aquatico), V95-V97 (aereo) e V98-V99 (nao especificados).
  filter(
    !is.na(mes),
    !is.na(cod_uf), cod_uf != "",
    str_starts(causabas, "V"),
    v_num >= 1, v_num <= 89
  )

# --- 3. Carrega populacoes --------------------------------------------------
ufs_lookup <- arrow::read_parquet(file.path(dir_brutos, "ufs_lookup.parquet"))
pop_uf     <- arrow::read_parquet(file.path(dir_brutos, "pop_uf_anual.parquet"))

pop_br_anual <- pop_uf |>
  group_by(ano) |>
  summarise(populacao = sum(populacao, na.rm = TRUE), .groups = "drop")

# --- 4. Bases agregadas -----------------------------------------------------

# 4.1 Mortes por ano - Brasil
mortes_br_ano <- mortes |>
  count(ano, name = "obitos") |>
  left_join(pop_br_anual, by = "ano") |>
  mutate(taxa_100k = obitos / populacao * 1e5) |>
  arrange(ano)

# 4.2 Mortes por ano e UF
mortes_uf_ano <- mortes |>
  count(ano, cod_uf, name = "obitos") |>
  left_join(pop_uf, by = c("ano", "cod_uf")) |>
  left_join(ufs_lookup |> select(cod_uf, nome_uf), by = "cod_uf") |>
  mutate(taxa_100k = obitos / populacao * 1e5) |>
  select(ano, cod_uf, sigla_uf, nome_uf, obitos, populacao, taxa_100k) |>
  arrange(ano, cod_uf)

# 4.3 Mortes por ano e mes - Brasil (para sazonalidade)
mortes_br_ano_mes <- mortes |>
  count(ano, mes, name = "obitos") |>
  arrange(ano, mes)

# --- 5. Salva as bases agregadas --------------------------------------------
arrow::write_parquet(mortes_br_ano,     file.path(dir_processados, "mortes_br_ano.parquet"))
arrow::write_parquet(mortes_uf_ano,     file.path(dir_processados, "mortes_uf_ano.parquet"))
arrow::write_parquet(mortes_br_ano_mes, file.path(dir_processados, "mortes_br_ano_mes.parquet"))

write_csv(mortes_br_ano,     file.path(dir_processados, "mortes_br_ano.csv"))
write_csv(mortes_uf_ano,     file.path(dir_processados, "mortes_uf_ano.csv"))
write_csv(mortes_br_ano_mes, file.path(dir_processados, "mortes_br_ano_mes.csv"))

# --- 6. BASE FINAL CONSOLIDADA ---------------------------------------------
# Base granular por ano + mes + UF, com populacao do UF naquele ano.
# E a tabela mais util para refazer qualquer agregacao depois.
base_completa <- mortes |>
  count(ano, mes, cod_uf, name = "obitos") |>
  left_join(ufs_lookup |> select(cod_uf, sigla_uf, nome_uf), by = "cod_uf") |>
  left_join(pop_uf |> select(ano, cod_uf, pop_uf = populacao),
            by = c("ano", "cod_uf")) |>
  select(ano, mes, cod_uf, sigla_uf, nome_uf, obitos, pop_uf) |>
  arrange(ano, mes, cod_uf)

arrow::write_parquet(base_completa, file.path(dir_processados, "base_completa.parquet"))
write_csv(base_completa,            file.path(dir_processados, "base_completa.csv"))

message("Bases processadas salvas em ", dir_processados)
message("Base completa: ", format(nrow(base_completa), big.mark = "."), " linhas, ",
        ncol(base_completa), " colunas.")
