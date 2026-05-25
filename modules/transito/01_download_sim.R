# =============================================================================
# 01_download_sim.R
# Baixa microdados do SIM-DO (DATASUS) para 2000-2024 via pacote microdatasus,
# filtra obitos por acidentes de transporte (CID-10 V01-V99) e salva um
# parquet por ano em dados/brutos/.
#
# Atencao: o download usa o FTP do DATASUS e pode demorar (~20-60 min total).
# Os arquivos sao cacheados: rodar de novo pula anos ja baixados.
# =============================================================================

source(here::here("scripts", "00_setup.R"))

anos <- 2000:2024

baixar_ano_sim <- function(ano) {
  arquivo <- file.path(dir_brutos, paste0("sim_do_v_", ano, ".parquet"))

  if (file.exists(arquivo)) {
    message(sprintf("[%d] ja existe, pulando.", ano))
    return(invisible(NULL))
  }

  message(sprintf("[%d] baixando SIM-DO...", ano))

  dados_ano <- tryCatch(
    microdatasus::fetch_datasus(
      year_start         = ano,
      year_end           = ano,
      information_system = "SIM-DO"
    ),
    error = function(e) {
      warning(sprintf("[%d] FALHOU: %s", ano, e$message))
      NULL
    }
  )

  if (is.null(dados_ano)) return(invisible(NULL))

  dados_v <- dados_ano |>
    as_tibble() |>
    filter(str_starts(as.character(CAUSABAS), "V")) |>
    transmute(
      ano             = ano,
      data_obito_raw  = as.character(DTOBITO),
      causabas        = as.character(CAUSABAS),
      cod_mun_ocor    = as.character(CODMUNOCOR),
      cod_mun_res     = as.character(CODMUNRES),
      idade_raw       = as.character(IDADE),
      sexo            = as.character(SEXO)
    )

  arrow::write_parquet(dados_v, arquivo)
  message(sprintf("[%d] salvos %s obitos por acidente de transporte.",
                  ano, format(nrow(dados_v), big.mark = ".")))

  invisible(NULL)
}

# Loop sequencial. Cada ano e independente do anterior.
walk(anos, baixar_ano_sim)

message("Download do SIM concluido.")
