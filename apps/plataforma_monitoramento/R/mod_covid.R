# apps/plataforma_monitoramento/R/mod_covid.R

# UI do Mdulo COVID
mod_covid_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(width = 12, status = "primary", solidHeader = TRUE,
          title = "Mortalidade por Ra\u00e7a/Cor e Sexo (PEA)",
          plotOutput(ns("plot_raca_sexo"), height = "500px")
      )
    ),
    fluidRow(
      box(width = 12, status = "danger", solidHeader = TRUE,
          title = "Mortalidade por Grupo Ocupacional",
          plotOutput(ns("plot_ocupacao"), height = "600px")
      )
    )
  )
}

# Server do Mdulo COVID
mod_covid_server <- function(id, data_raca_sexo, data_ocupacao) {
  moduleServer(id, function(input, output, session) {
    
    output$plot_raca_sexo <- renderPlot({
      req(nrow(data_raca_sexo()) > 0)
      plot_covid_raca_sexo(data_raca_sexo())
    })
    
    output$plot_ocupacao <- renderPlot({
      req(nrow(data_ocupacao()) > 0)
      plot_covid_ocupacao(data_ocupacao())
    })
    
  })
}
