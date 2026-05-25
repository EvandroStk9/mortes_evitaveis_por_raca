# =============================================================================
# 02_download_pop.R
# Baixa populacao por UF e ano da SIDRA tabela 7358 (Projecao da populacao
# do Brasil e UFs, IBGE, revisao 2018) via pacote sidrar.
#
# A tabela cobre 2000-2060 em uma unica query. Filtramos Sexo=Total,
# Idade=Total e todos os anos (c1933=all). Saida: pop_uf_anual.parquet
# com colunas (ano, cod_uf, sigla_uf, populacao).
#
# Observacao: 7358 e a projecao de 2018 (pre-Censo 2022). Para anos
# pos-2022 os valores sao projecoes, nao estimativas atualizadas pelo
# Censo - mas oferece serie continua e uniforme metodologicamente.
# =============================================================================

source(here::here("scripts", "00_setup.R"))

# Lookup de UFs (codigo IBGE -> sigla -> nome)
ufs_lookup <- tibble::tribble(
  ~cod_uf, ~sigla_uf, ~nome_uf,
  "11", "RO", "Rondonia",
  "12", "AC", "Acre",
  "13", "AM", "Amazonas",
  "14", "RR", "Roraima",
  "15", "PA", "Para",
  "16", "AP", "Amapa",
  "17", "TO", "Tocantins",
  "21", "MA", "Maranhao",
  "22", "PI", "Piaui",
  "23", "CE", "Ceara",
  "24", "RN", "Rio Grande do Norte",
  "25", "PB", "Paraiba",
  "26", "PE", "Pernambuco",
  "27", "AL", "Alagoas",
  "28", "SE", "Sergipe",
  "29", "BA", "Bahia",
  "31", "MG", "Minas Gerais",
  "32", "ES", "Espirito Santo",
  "33", "RJ", "Rio de Janeiro",
  "35", "SP", "Sao Paulo",
  "41", "PR", "Parana",
  "42", "SC", "Santa Catarina",
  "43", "RS", "Rio Grande do Sul",
  "50", "MS", "Mato Grosso do Sul",
  "51", "MT", "Mato Grosso",
  "52", "GO", "Goias",
  "53", "DF", "Distrito Federal"
)

arrow::write_parquet(ufs_lookup, file.path(dir_brutos, "ufs_lookup.parquet"))

# --- Populacao anual por UF (SIDRA 7358) ------------------------------------
arquivo_pop_uf <- file.path(dir_brutos, "pop_uf_anual.parquet")

if (!file.exists(arquivo_pop_uf)) {
  message("Baixando projecao IBGE - SIDRA tabela 7358...")

  # URL no padrao SIDRA. Esta forma contorna um bug do sidrar com classific
  # de tamanho > 1 ('length = N em coercao a logical(1)').
  #
  # /t/7358   -> tabela
  # /n3/all   -> nivel 3 (UF), todas
  # /v/606    -> variavel 'Populacao'
  # /p/2018   -> periodo (release da projecao)
  # /c2/6794  -> sexo = Total
  # /c287/100362 -> idade = Total
  # /c1933/all   -> ano (c1933) = todos
  url_sidra <- "/t/7358/n3/all/v/606/p/2018/c2/6794/c287/100362/c1933/all"

  # Manter como data.frame: as_tibble() falha por causa do nome "Ano"
  # duplicado (periodo + c1933). Acessamos colunas pela posicao abaixo.
  raw <- sidrar::get_sidra(api = url_sidra)

  # A coluna "Ano" aparece duas vezes (periodo da query e c1933). A 2a
  # ocorrencia tem o ano-alvo da projecao (string "2000".."2060"). Pegamos
  # essa pela posicao para evitar ambiguidade.
  idx_ano_cols <- which(names(raw) == "Ano")
  ano_real     <- raw[[idx_ano_cols[length(idx_ano_cols)]]]

  pop_uf_anual <- tibble(
    ano       = as.integer(ano_real),
    cod_uf    = as.character(raw[["Unidade da Federação (Código)"]]),
    populacao = as.numeric(raw[["Valor"]])
  ) |>
    filter(ano >= 2000, ano <= 2024) |>
    inner_join(ufs_lookup |> select(cod_uf, sigla_uf), by = "cod_uf") |>
    select(ano, cod_uf, sigla_uf, populacao) |>
    arrange(ano, cod_uf)

  arrow::write_parquet(pop_uf_anual, arquivo_pop_uf)
  message(sprintf("Salvo: %d linhas | anos %d-%d | %d UFs.",
                  nrow(pop_uf_anual),
                  min(pop_uf_anual$ano), max(pop_uf_anual$ano),
                  n_distinct(pop_uf_anual$cod_uf)))
} else {
  message("Pop UF anual ja existe, pulando.")
}

message("Download de populacao concluido.")
