# src/03_modules_gen.R
# Gerador de Módulos (Engine de Agregação: Staging -> Gold)
library(tidyverse)
library(arrow)
library(here)
library(yaml)

message("--- Gerando módulos analíticos (Gold Layer) ---")

# Carrega base tratada (Staging)
df_staging <- read_parquet(here("data/staging/full_sim.parquet"))

# Engine processadora (Metadata-Driven)
run_metadata_engine <- function(yaml_file) {
  meta <- yaml::read_yaml(yaml_file)
  message("Gerando arquivo Gold para: ", meta$nome)

  # Filtro dinâmico baseado no CID e ano de início
  df_filtered <- df_staging %>%
    filter(
      str_detect(causabas, meta$metodologia$cid_regex),
      ano >= meta$metodologia$filtros$ano_inicio 
    )

  # Garante que colunas essenciais para visualização (ano_trimestre, raca_agreg, sexo, causabas)
  # estejam presentes na agregação para suportar filtros e gráficos temporais/demográficos.
  colunas_obrigatorias <- c("ano_trimestre", "raca_agreg", "sexo", "causabas")
  agregacoes_meta <- meta$metodologia$agregacoes %||% character(0)
  agregacoes_finais <- unique(c(colunas_obrigatorias, agregacoes_meta))

  agregacoes_syms <- rlang::syms(agregacoes_finais)

  df_agregado <- df_filtered %>%
    group_by(!!!agregacoes_syms) %>%
    summarise(total = n(), .groups = "drop")

  # Salva metadados junto com os dados ou garante o padrão de nome
  output_path <- here(paste0("app/data/", meta$id, ".parquet"))
  write_parquet(df_agregado, output_path)

  message("  [OK] ", meta$id, " -> ", nrow(df_agregado), " linhas.")
}

# Execução
dir.create(here("app/data/"), showWarnings = FALSE)
yaml_files <- list.files(here("metadata"), "*.yaml", full.names = TRUE)
walk(yaml_files, run_metadata_engine)

message("--- Módulos Gold gerados com sucesso ---")

