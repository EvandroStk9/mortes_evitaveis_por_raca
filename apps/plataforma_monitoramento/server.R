# apps/plataforma_monitoramento/server.R

function(input, output, session) {
  
  # Carregamento Reativo dos Dados Gold
  data_transito <- reactive({
    # No pipeline atual o nome  'transito_gold'
    dat <- get_gold_data("transito_gold")
    if (is.null(dat)) return(tibble())
    dat
  })
  
  data_covid <- reactive({
    # Se o dado de COVID ainda no existir, retorna um tibble vazio
    dat <- get_gold_data("covid_gold")
    if (is.null(dat)) return(tibble())
    dat
  })
  
  # Inicializao dos Mdulos
  mod_indicadores_server("transito_ui", data_transito)
  mod_indicadores_server("covid_ui", data_covid)
  
}
