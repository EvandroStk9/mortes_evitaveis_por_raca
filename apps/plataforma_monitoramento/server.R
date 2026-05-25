# apps/plataforma_monitoramento/server.R

function(input, output, session) {
  
  # --- DADOS TRNSITO ---
  transito_ano <- reactive({
    load_platform_data("mortes_br_ano.parquet")
  })
  
  transito_mes <- reactive({
    load_platform_data("mortes_br_ano_mes.parquet")
  })
  
  # --- DADOS COVID (Simulao Baseada no Original) ---
  covid_raca_sexo <- reactive({
    # Simulando estrutura do ggplot original do Rmd
    tibble(
      raca_cor = rep(c("Branca", "Preta", "Parda", "Amarela", "Indgena"), each = 2),
      sexo = rep(c("Homem", "Mulher"), 5),
      obitos = sample(1000:20000, 10)
    )
  })
  
  covid_ocupacao <- reactive({
    # Simulando estrutura do grfico de disperso
    tibble(
      grupo = paste("Grupo", 1:15),
      obitos_covid = sample(500:5000, 15),
      obitos_total = sample(5000:50000, 15)
    ) %>%
      mutate(obitos_covid_cada_100_grupo = (obitos_covid / obitos_total) * 100)
  })
  
  # Inicializao dos Mdulos
  mod_indicadores_server("transito_ui", transito_ano, transito_mes)
  mod_covid_server("covid_ui", covid_raca_sexo, covid_ocupacao)
  
}
