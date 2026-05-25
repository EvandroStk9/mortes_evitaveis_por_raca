# apps/plataforma_monitoramento/app.R
library(shiny); library(shinydashboard); library(tidyverse); library(arrow); library(here); library(plotly)

ui <- dashboardPage(
  dashboardHeader(title = "Plataforma CEBRAP"),
  dashboardSidebar(sidebarMenu(
    menuItem("COVID-19", tabName = "covid"),
    menuItem("Trânsito", tabName = "transito")
  )),
  dashboardBody(
    tabItems(
      tabItem(tabName = "covid", box(width=12, plotlyOutput("plot_covid"), textOutput("txt_covid"))),
      tabItem(tabName = "transito", box(width=12, plotlyOutput("plot_transito"), textOutput("txt_transito")))
    )
  )
)

server <- function(input, output) {
  # Carregamento seguro
  load_safe <- function(name) {
    path <- here("data/gold", paste0(name, ".parquet"))
    if(file.exists(path)) read_parquet(path) else NULL
  }
  
  output$plot_covid <- renderPlotly({
    df <- load_safe("covid_gold")
    req(df, "Gráfico COVID indisponível - verifique data/raw/covid/sim.parquet")
    p <- ggplot(df, aes(x=ano, y=total, fill=raca_agreg)) + geom_col() + theme_minimal()
    ggplotly(p)
  })
  
  output$plot_transito <- renderPlotly({
    df <- load_safe("transito_gold")
    req(df, "Gráfico Trânsito indisponível - verifique data/raw/transito/")
    p <- ggplot(df, aes(x=ano, y=total, fill=raca_agreg)) + geom_col() + theme_minimal()
    ggplotly(p)
  })
}

shinyApp(ui, server)
