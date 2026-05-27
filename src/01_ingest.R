# src/01_ingest.R

library(tidyverse)
library(arrow)
library(here)
library(microdatasus)
library(lubridate)
library(furrr)
library(future)

options(timeout = 600)

# =========================================================
# Diretórios
# =========================================================

raw_dir <- here("data/raw/sim")
log_dir <- here("data/logs")

dir.create(
  raw_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  log_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

log_file <- here("logs/falhas_ingestao.txt")

# =========================================================
# Descobrir anos já existentes
# =========================================================

arquivos_existentes <- list.files(
  raw_dir,
  pattern = "\\.parquet$",
  full.names = TRUE
)

if (length(arquivos_existentes) > 0) {
  
  anos_existentes <- arquivos_existentes %>%
    basename() %>%
    str_remove("\\.parquet$") %>%
    as.integer() %>%
    unique()
  
} else {
  
  anos_existentes <- integer(0)
  
}

# =========================================================
# Definir anos necessários
# =========================================================

ano_fim <- year(today()) - 2

anos_necessarios <- sort(setdiff(
  2000:ano_fim,
  anos_existentes
))

message(
  "Anos pendentes: ",
  paste(anos_necessarios, collapse = ", ")
)

if (length(anos_necessarios) == 0) {
  
  message("Nenhum ano pendente.")
  
  return(invisible(NULL))
  
}

# =========================================================
# Paralelização
# =========================================================

n_workers <- min(
  4,
  max(1, parallel::detectCores() - 1)
)

plan(multisession, workers = n_workers)

message("Workers utilizados: ", n_workers)

# =========================================================
# Função auxiliar de log
# =========================================================

registrar_log <- function(texto) {
  
  cat(
    paste0(
      Sys.time(),
      " | ",
      texto,
      "\n"
    ),
    file = log_file,
    append = TRUE
  )
  
}

# =========================================================
# Função de download
# =========================================================

baixar_salvar_ano <- function(ano) {
  
  tryCatch({
    
    message("Baixando ano: ", ano)
    
    arquivo_final <- file.path(
      raw_dir,
      paste0(ano, ".parquet")
    )
    
    dados <- tryCatch({
      
      fetch_datasus(
        year_start = ano,
        year_end = ano,
        uf = "all",
        information_system = "SIM-DO"
      )
      
    }, error = function(e) {
      
      registrar_log(
        paste0(
          "Erro fetch_datasus ano ",
          ano,
          ": ",
          e$message
        )
      )
      
      return(NULL)
      
    })
    
    if (is.null(dados) || nrow(dados) == 0) {
      
      message("Ano ", ano, " sem dados.")
      
      registrar_log(
        paste0(
          "Ano ",
          ano,
          " sem dados."
        )
      )
      
      return(NULL)
      
    }
    
    dados_processados <- tryCatch({
      
      dados %>%
        process_sim()
      
    }, error = function(e) {
      
      message(
        "Erro no process_sim() para ",
        ano,
        ": ",
        e$message
      )
      
      registrar_log(
        paste0(
          "Erro process_sim ano ",
          ano,
          ": ",
          e$message
        )
      )
      
      message(
        "Salvando versão sem processamento."
      )
      
      dados
      
    })
    
    dados_processados <- dados_processados %>%
      mutate(across(everything(), as.character))
    
    write_parquet(
      dados_processados,
      arquivo_final,
      compression = "zstd"
    )
    
    rm(dados)
    rm(dados_processados)
    
    gc()
    
    message("Ano ", ano, " salvo.")
    
    registrar_log(
      paste0(
        "Ano ",
        ano,
        " salvo com sucesso."
      )
    )
    
    return(arquivo_final)
    
  }, error = function(e) {
    
    message(
      "Erro fatal no ano ",
      ano,
      ": ",
      e$message
    )
    
    registrar_log(
      paste0(
        "Erro fatal ano ",
        ano,
        ": ",
        e$message
      )
    )
    
    return(NULL)
    
  })
}

# =========================================================
# Download paralelo
# =========================================================

resultado <- future_map(
  anos_necessarios,
  baixar_salvar_ano,
  .progress = TRUE
)

plan(sequential)

gc()

message("Ingestão concluída.")

# =========================================================
# Cria série histórica consolidada
# =========================================================

raw_dir <- here("data/raw/sim")

arquivos_raw <- list.files(
  raw_dir,
  pattern = "\\.parquet$",
  full.names = TRUE
)

# Evita empilhar o próprio full_sim.parquet
arquivos_raw <- arquivos_raw[
  !stringr::str_detect(arquivos_raw, "full_sim\\.parquet$")
]

dataset_raw <- open_dataset(arquivos_raw)

df_full_sim <- dataset_raw %>%
  collect()

write_parquet(
  df_full_sim,
  here("data/raw/full_sim.parquet")
)

message("Base consolidada full_sim.parquet criada.")

# =========================================================
# Validação dos dados baixados
# =========================================================

message("Validando integridade dos arquivos...")

validacao <- tibble(
  arquivo = arquivos_raw
) %>%
  mutate(
    
    ano = basename(arquivo) %>%
      stringr::str_remove("\\.parquet$") %>%
      as.integer(),
    
    tamanho_mb = round(
      file.size(arquivo) / 1024^2,
      2
    ),
    
    n_linhas = map_dbl(
      arquivo,
      ~ tryCatch(
        open_dataset(.x) %>%
          summarise(n = n()) %>%
          collect() %>%
          pull(n),
        error = function(e) NA_real_
      )
    ),
    
    n_colunas = map_int(
      arquivo,
      ~ tryCatch(
        length(open_dataset(.x)$schema$names),
        error = function(e) NA_integer_
      )
    ),
    
    colunas = map_chr(
      arquivo,
      ~ tryCatch(
        paste(
          sort(open_dataset(.x)$schema$names),
          collapse = ";"
        ),
        error = function(e) NA_character_
      )
    )
    
  ) %>%
  
  arrange(ano) %>%
  
  mutate(
    
    variacao_linhas = n_linhas / lag(n_linhas),
    
    status = case_when(
      is.na(n_linhas) ~ "corrompido",
      n_linhas == 0 ~ "vazio",
      tamanho_mb < 1 ~ "suspeito",
      variacao_linhas < 0.5 ~ "queda_brusca",
      variacao_linhas > 1.5 ~ "crescimento_brusco",
      TRUE ~ "ok"
    )
    
  ) %>%
  
  select(
    ano,
    status,
    n_linhas,
    tamanho_mb,
    n_colunas,
    variacao_linhas
  )

print(validacao)

write_csv(
  validacao,
  here("data/logs/raw_sim_validacao.csv")
)

message(
  "Relatório salvo em data/logs/raw_sim_validacao.csv"
)