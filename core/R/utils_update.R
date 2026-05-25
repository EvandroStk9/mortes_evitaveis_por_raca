# core/R/utils_update.R
# Estratgia de Atualizao Automatizada

#' Verifica se h novos dados no FTP do DATASUS
#' @param system O sistema (SIM, SINASC, etc)
#' @param years Anos a verificar
check_new_data <- function(system = "SIM-DO", years = lubridate::year(Sys.Date())) {
  # Lgica para verificar datas de modificao no FTP
  # Por enquanto, comparamos com o log local de atualizaes
  last_update_log <- read_csv(here::here("data/update_log.csv"))
  
  # Exemplo de lgica: se o ano atual no est no log, precisamos atualizar
  latest_logged_year <- max(last_update_log$ano)
  
  if (max(years) > latest_logged_year) {
    return(TRUE)
  }
  return(FALSE)
}

#' Registra uma nova rodada do pipeline
log_update <- function(module, status = "success") {
  log_entry <- tibble(
    timestamp = Sys.time(),
    module = module,
    status = status,
    r_version = R.version.string
  )
  
  write_csv(log_entry, here::here("data/update_log.csv"), append = TRUE)
}

#' Dispara o pipeline apenas se necessrio
auto_update_pipeline <- function() {
  if (check_new_data()) {
    message("Novos dados detectados. Iniciando pipeline...")
    targets::tar_make()
    log_update("all")
  } else {
    message("Dados j esto atualizados. Nenhuma ao necessria.")
  }
}
