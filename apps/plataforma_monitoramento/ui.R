# apps/plataforma_monitoramento/ui.R
library(shiny)
library(shinydashboard)

# Garante encoding UTF-8 no UI
header <- dashboardHeader(
  title = "Mortes Evit\u00e1veis", 
  titleWidth = 300
)

sidebar <- dashboardSidebar(
  width = 300,
  sidebarMenu(
    menuItem("Vis\u00e3o Geral", tabName = "geral", icon = icon("dashboard")),
    menuItem("Tr\u00e2nsito (Original)", tabName = "transito", icon = icon("car")),
    menuItem("COVID-19 (Original)", tabName = "covid", icon = icon("virus")),
    menuItem("Metodologia", tabName = "metodo", icon = icon("book"))
  )
)

body <- dashboardBody(
  tags$head(
    tags$style(HTML("
      .content-wrapper { background-color: #f4f6f9; }
      .main-header .logo { font-weight: bold; }
    "))
  ),
  tabItems(
    tabItem(tabName = "transito",
            h2("An\u00e1lise de Mortes no Tr\u00e2nsito (Fidelidade Original)"),
            mod_indicadores_ui("transito_ui")
    ),
    tabItem(tabName = "covid",
            h2("An\u00e1lise COVID-19 (Fidelidade Original)"),
            mod_covid_ui("covid_ui")
    )
  )
)

dashboardPage(header, sidebar, body, skin = "blue")
