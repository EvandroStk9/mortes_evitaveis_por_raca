# apps/plataforma_monitoramento/R/mod_indicadores.R

# UI do Mdulo
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

# Server do Mdulo
mod_indicadores_server <- function(id, data_target) {
  moduleServer(id, function(input, output, session) {
    
    # Reativo para filtrar dados
    df_filtrado <- reactive({
      res <- data_target()
      
      # Se a tabela for vazia ou no tiver a coluna, retorna como est
      if (nrow(res) == 0 || !"raca_cor_ibge" %in% names(res)) {
        return(res)
      }
      
      if (input$select_raca != "Todas") {
        res <- res %>% filter(raca_cor_ibge == input$select_raca)
      }
      res
    })
    
    output$plot_tendencia <- renderPlot({
      req(nrow(df_filtrado()) > 0)
      
      df_filtrado() %>%
        ggplot(aes(x = ano, y = taxa_mortalidade, color = raca_cor_agreg)) +
        geom_line(linewidth = 1.2) +
        geom_point() +
        labs(title = "Evoluo da Taxa por 100k Habitantes",
             x = "Ano", y = "Taxa", color = "Raa/Cor") +
        tema_plataforma()
    })
    
    output$tabela_gold <- DT::renderDT({
      req(nrow(df_filtrado()) > 0)
      df_filtrado() %>% 
        DT::datatable(options = list(pageLength = 10))
    })
  })
}
