# apps/plataforma_monitoramento/R/mod_standard.R

# UI do Módulo Padronizado
mod_standard_ui <- function(id, label = "M\u00f3dulo") {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(width = 8, status = "primary", solidHeader = TRUE,
          title = paste("Tend\u00eancia Trimestral de Mortalidade -", label),
          plotOutput(ns("plot_tendencia"), height = "400px")
      ),
      box(width = 4, status = "warning", solidHeader = TRUE,
          title = "Controle de An\u00e1lise",
          # Select dinâmico será atualizado no server
          selectInput(ns("select_uf"), "Filtrar por UF:", choices = "Brasil"),
          checkboxGroupInput(ns("show_raca"), "Grupos Raciais:",
                             choices = c("Branca", "Negra", "Ind\u00edgena", "Amarela"),
                             selected = c("Branca", "Negra"))
      )
    ),
    fluidRow(
      box(width = 12, status = "info", solidHeader = TRUE,
          title = "Raz\u00e3o de Taxas (Rate Ratio)",
          plotOutput(ns("plot_disparidade"), height = "300px")
      )
    )
  )
}

# Server do Módulo Padronizado
mod_standard_server <- function(id, data_target) {
  moduleServer(id, function(input, output, session) {
    
    # Atualiza lista de UFs dinamicamente baseada nos dados
    observe({
      req(nrow(data_target()) > 0)
      ufs <- sort(unique(data_target()$nome_uf))
      updateSelectInput(session, "select_uf", choices = c("Brasil", ufs))
    })
    
    # Dados Filtrados por UF e Raça
    df_ready <- reactive({
      req(nrow(data_target()) > 0)
      res <- data_target()
      
      # Filtro de UF
      if (input$select_uf != "Brasil") {
        res <- res %>% filter(nome_uf == input$select_uf)
      }
      
      # Filtro de Raça
      res %>% filter(raca_cor_agreg %in% input$show_raca)
    })
    
    # Gráficos Institucionais usando ano_trimestre
    output$plot_tendencia <- renderPlot({
      req(nrow(df_ready()) > 0)
      
      df_ready() %>%
        ggplot(aes(x = ano_trimestre, y = taxa_mortalidade, color = raca_cor_agreg, group = raca_cor_agreg)) +
        geom_line(linewidth = 1.2) +
        geom_point(size = 3) +
        get_cebrap_color_scale() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
        labs(title = "Taxa de Mortalidade Trimestral", x = "Trimestre (Ano-M\u00eas Final)", y = "Taxa por 100k") +
        tema_plataforma()
    })
    
    output$plot_disparidade <- renderPlot({
      req(nrow(df_ready()) > 0)
      # Adaptando a função de disparidade para o eixo trimestral
      plot_disparidade_raca_trimestral(df_ready())
    })
    
  })
}
