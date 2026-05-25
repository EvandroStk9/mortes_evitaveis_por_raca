# apps/plataforma_monitoramento/R/mod_indicadores.R

# UI do Módulo
mod_indicadores_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(width = 3, title = "Filtros", status = "primary", solidHeader = TRUE,
          selectInput(ns("select_raca"), "Raa/Cor:", 
                      choices = c("Todas", "Branca", "Preta", "Parda", "Amarela", "Indgena")),
          selectInput(ns("select_uf"), "Estado:", choices = NULL)
      ),
      box(width = 9, title = "Tendncia Temporal", status = "info", solidHeader = TRUE,
          plotOutput(ns("plot_tendencia"))
      )
    ),
    fluidRow(
      box(width = 12, title = "Tabela de Indicadores", 
          DT::DTOutput(ns("tabela_gold")))
    )
  )
}

# Server do Módulo
mod_indicadores_server <- function(id, data_target) {
  moduleServer(id, function(input, output, session) {
    
    # Reativo para filtrar dados
    df_filtrado <- reactive({
      res <- data_target()
      if (input$select_raca != "Todas") {
        res <- res %>% filter(raca_cor == input$select_raca)
      }
      res
    })
    
    output$plot_tendencia <- renderPlot({
      df_filtrado() %>%
        ggplot(aes(x = ano, y = taxa_mortalidade, color = raca_cor)) +
        geom_line(size = 1.2) +
        geom_point() +
        labs(title = "Evoluo da Taxa por 100k Habitantes",
             x = "Ano", y = "Taxa") +
        tema_plataforma() # Usa o tema definido no core
    })
    
    output$tabela_gold <- DT::renderDT({
      df_filtrado() %>% 
        DT::datatable(options = list(pageLength = 10))
    })
  })
}
