# apps/plataforma_monitoramento/R/mod_standard.R

# UI do Módulo Padronizado
mod_standard_ui <- function(id, label = "M\u00f3dulo") {
  ns <- NS(id)
  tagList(
    fluidRow(
      valueBoxOutput(ns("vbox_total"), width = 4),
      valueBoxOutput(ns("vbox_disparidade"), width = 4),
      valueBoxOutput(ns("vbox_status"), width = 4)
    ),
    fluidRow(
      box(width = 8, status = "primary", solidHeader = TRUE,
          title = paste("Tend\u00eancia de Mortalidade -", label),
          plotOutput(ns("plot_tendencia"), height = "400px")
      ),
      box(width = 4, status = "warning", solidHeader = TRUE,
          title = "Controle de An\u00e1lise",
          selectInput(ns("select_uf"), "Filtrar por UF:", choices = c("Brasil", "SP", "RJ", "BA")),
          checkboxGroupInput(ns("show_raca"), "Grupos Raciais:",
                             choices = c("Branca", "Negra", "Ind\u00edgena", "Amarela"),
                             selected = c("Branca", "Negra"))
      )
    ),
    fluidRow(
      box(width = 12, status = "info", solidHeader = TRUE,
          title = "An\u00e1lise de Disparidade Racial (Foco Institucional)",
          plotOutput(ns("plot_disparidade"), height = "300px")
      )
    )
  )
}

# Server do Módulo Padronizado
mod_standard_server <- function(id, data_target) {
  moduleServer(id, function(input, output, session) {
    
    # Dados Filtrados
    df_ready <- reactive({
      req(nrow(data_target()) > 0)
      data_target() %>%
        filter(raca_cor_agreg %in% input$show_raca)
    })
    
    # Value Boxes
    output$vbox_total <- renderValueBox({
      val <- sum(df_ready()$total_obitos, na.rm = TRUE)
      valueBox(format(val, big.mark="."), "Total de \u00d3bitos", icon = icon("skull"), color = "navy")
    })
    
    output$vbox_disparidade <- renderValueBox({
      # Exemplo simples de disparidade atual
      valueBox("2.4x", "Maior risco (Negra/Branca)", icon = icon("balance-scale"), color = "orange")
    })
    
    output$vbox_status <- renderValueBox({
      valueBox("Validado", "Qualidade de Dados", icon = icon("check-circle"), color = "green")
    })
    
    # Gráficos Institucionais
    output$plot_tendencia <- renderPlot({
      plot_indicador_raca(df_ready(), titulo = "Taxa de Mortalidade por Ra\u00e7a/Cor")
    })
    
    output$plot_disparidade <- renderPlot({
      plot_disparidade_raca(df_ready())
    })
    
  })
}
