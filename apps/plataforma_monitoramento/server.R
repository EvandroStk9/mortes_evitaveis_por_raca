# apps/plataforma_monitoramento/server.R

function(input, output, session) {
  
  # --- DADOS TRNSITO (Padronizado) ---
  data_transito_std <- reactive({
    # Puxa o target gerado pelo pipeline
    dat <- get_gold_data("transito_gold")
    if (is.null(dat)) return(tibble())
    dat
  })
  
  # --- DADOS COVID (Simulado para Demonstração de Estrutura) ---
  data_covid_std <- reactive({
    # Simula o que o pipeline de COVID vai gerar (Camada Gold)
    expand.grid(
      ano = 2020:2023,
      raca_cor_agreg = c("Branca", "Negra", "Ind\u00edgena", "Amarela"),
      stringsAsFactors = FALSE
    ) %>%
      as_tibble() %>%
      mutate(
        total_obitos = sample(100:5000, n()),
        populacao = 1000000,
        taxa_mortalidade = (total_obitos / populacao) * 100000
      )
  })
  
  # --- DADOS PARA VERSO ORIGINAL ---
  transito_ano <- reactive({ load_platform_data("mortes_br_ano.parquet") })
  transito_mes <- reactive({ load_platform_data("mortes_br_ano_mes.parquet") })
  
  # Inicializao dos Mdulos Padronizados
  mod_standard_server("transito_std", data_transito_std)
  mod_standard_server("covid_std", data_covid_std)
  
  # Inicializao dos Mdulos de Histrico (Fidelidade)
  mod_indicadores_server("transito_ui", transito_ano, transito_mes)
  mod_covid_server("covid_ui", reactive(tibble()), reactive(tibble()))
  
}
