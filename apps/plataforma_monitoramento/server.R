# apps/plataforma_monitoramento/server.R

function(input, output, session) {
  
  # Carregamento Reativo dos Dados Gold
  # Garante que o app use a verso mais recente do pipeline
  data_transito <- reactive({
    get_gold_data("transito_stg") # Exemplo de target
  })
  
  data_covid <- reactive({
    get_gold_data("covid_gold")
  })
  
  # Inicializao dos Mdulos
  mod_indicadores_server("transito_ui", data_transito)
  mod_indicadores_server("covid_ui", data_covid)
  
}
