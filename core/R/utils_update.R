# core/R/utils_update.R
# Estratgia de Atualizao Automatizada

#' Verifica se h novos dados no FTP do DATASUS
#' @param system O sistema (SIM, SINASC, etc)
#' @param years Anos a verificar
check_new_data <- function(system = "SIM-DO", years = lubridate::year(Sys.Date())) {
  log_path <- here::here("data/update_log.csv")
  
  # Se o log no existe, precisamos atualizar
  if (!file.exists(log_path)) {
    return(TRUE)
  }
  
  last_update_log <- readr::read_csv(log_path, show_col_types = FALSE)
  
  if (nrow(last_update_log) == 0) {
    return(TRUE)
  }
  
  # Exemplo de lgica: se o ano atual no est no log, precisamos atualizar
  latest_logged_year <- max(last_update_log$ano, na.rm = TRUE)
  
  if (max(years, na.rm = TRUE) > latest_logged_year) {
    return(TRUE)
  }
  return(FALSE)
}

#' Registra uma nova rodada do pipeline
log_update <- function(module, status = "success", ano = lubridate::year(Sys.Date())) {
  log_path <- here::here("data/update_log.csv")
  
  log_entry <- tibble::tibble(
    timestamp = Sys.time(),
    module = module,
    status = status,
    r_version = R.version.string,
    ano = ano
  )
  
  if (!file.exists(log_path)) {
    readr::write_csv(log_entry, log_path)
  } else {
    readr::write_csv(log_entry, log_path, append = TRUE)
  }
}

#' Dispara o pipeline apenas se necessrio
auto_update_pipeline <- function() {
  if (check_new_data()) {
    message("Novos dados detectados ou log ausente. Iniciando pipeline...")
    targets::tar_make()
    log_update("all")
  } else {
    message("Dados j esto atualizados. Nenhuma ao necessria.")
  }
}
