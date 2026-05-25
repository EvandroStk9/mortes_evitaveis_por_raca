# apps/plataforma_monitoramento/server.R

function(input, output, session) {
  
  # Dados de Trânsito (Fidelidade ao repositório original)
  transito_ano <- reactive({
    load_platform_data("mortes_br_ano.parquet")
  })
  
  transito_mes <- reactive({
    load_platform_data("mortes_br_ano_mes.parquet")
  })
  
  # Inicialização dos Módulos com múltiplos datasets
  mod_indicadores_server("transito_ui", transito_ano, transito_mes)
  
  # Placeholder para COVID
  mod_indicadores_server("covid_ui", reactive(tibble()), reactive(tibble()))
  
}
