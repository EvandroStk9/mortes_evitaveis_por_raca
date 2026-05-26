options(scipen = 999) # Evita notação científica)

# Dashboard consolidado - Lê dados Gold padronizados
library(shiny)
library(shinydashboard)
library(tidyverse)
library(arrow)
library(here)
library(plotly)

ui <- dashboardPage(
  dashboardHeader(title = "Mortes evitáveis"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Trânsito", tabName = "transito"),
      menuItem("COVID-19", tabName = "covid"),
      menuItem("APS", tabName = "aps")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "transito", box(width=12, plotlyOutput("plot_transito"))),
      tabItem(tabName = "covid", box(width=12, plotlyOutput("plot_covid"))),
      tabItem(tabName = "aps", box(width=12, plotlyOutput("plot_aps")))
    )
  )
)

server <- function(input, output) {
  render_plot <- function(file) {
    path <- here("data/gold", file)
    validate(
      need(file.exists(path), paste("Arquivo não encontrado:", path))
    )
    df <- read_parquet(path)
    
    p <- ggplot(df, aes(x = ano_trimestre, y = total, fill = raca_agreg,
                        text = paste("Ano:", ano_trimestre, "<br>Raça:", raca_agreg, "<br>Total:", total))) +
      geom_col(position = "stack") + theme_minimal() + 
      labs(x="Ano", y="Total", fill="Raça")
    
    ggplotly(p, tooltip = "text")
  }
  
  output$plot_transito <- renderPlotly({ render_plot("transito_gold.parquet") })
  output$plot_covid <- renderPlotly({ render_plot("covid_gold.parquet") })
  output$plot_aps <- renderPlotly({ render_plot("aps_gold.parquet") })
}

shinyApp(ui, server)
