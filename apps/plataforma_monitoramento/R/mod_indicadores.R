# apps/plataforma_monitoramento/R/mod_indicadores.R

# UI do Módulo
mod_indicadores_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE,
          title = "Tendência Nacional e Taxa por 100k",
          column(6, plotOutput(ns("plot_total"))),
          column(6, plotOutput(ns("plot_taxa")))
      )
    ),
    fluidRow(
      box(width = 8, status = "info", solidHeader = TRUE,
          title = "Sazonalidade Mensal",
          plotOutput(ns("plot_heatmap"))
      ),
      box(width = 4, status = "warning", solidHeader = TRUE,
          title = "Filtros e Exportação",
          selectInput(ns("select_raca"), "Raça/Cor:", 
                      choices = c("Todas", "Branca", "Negra", "Indígena", "Amarela")),
          downloadButton(ns("download_data"), "Baixar Dados (CSV)")
      )
    )
  )
}

# Server do Módulo
mod_indicadores_server <- function(id, data_total, data_mes) {
  moduleServer(id, function(input, output, session) {
    
    # Plot 1: Total de Óbitos (Estilo Amarelo Original)
    output$plot_total <- renderPlot({
      req(nrow(data_total()) > 0)
      plot_tendencia_nacional(
        data_total(), 
        col_y = "obitos", 
        titulo = "Mortes Totais no Brasil",
        subtitulo = "Série Histórica (2000-2024)",
        cor = cores_maio$amarelo
      )
    })
    
    # Plot 2: Taxa por 100k (Estilo Vermelho Original)
    output$plot_taxa <- renderPlot({
      req(nrow(data_total()) > 0)
      plot_tendencia_nacional(
        data_total(), 
        col_y = "taxa_100k", 
        titulo = "Taxa por 100 mil habitantes",
        subtitulo = "Indicador de risco populacional",
        cor = cores_maio$vermelho
      )
    })
    
    # Plot 3: Heatmap Sazonalidade
    output$plot_heatmap <- renderPlot({
      req(nrow(data_mes()) > 0)
      plot_heatmap_sazonalidade(data_mes())
    })
    
    # Download
    output$download_data <- downloadHandler(
      filename = function() { paste0(id, "_data.csv") },
      content = function(file) { write.csv(data_total(), file) }
    )
  })
}
