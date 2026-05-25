# apps/plataforma_monitoramento/ui.R
library(shiny)
library(shinydashboard)

header <- dashboardHeader(title = "Monitoramento de Desigualdades Raciais", titleWidth = 350)

sidebar <- dashboardSidebar(
  width = 350,
  sidebarMenu(
    menuItem("Dashboard Geral", tabName = "geral", icon = icon("dashboard")),
    menuItem("Mortes no Trnsito", tabName = "transito", icon = icon("car")),
    menuItem("COVID-19", tabName = "covid", icon = icon("virus")),
    menuItem("Metodologia", tabName = "metodo", icon = icon("book"))
  )
)

body <- dashboardBody(
  tabItems(
    tabItem(tabName = "transito",
            h2("Anlise de Mortes no Trnsito"),
            mod_indicadores_ui("transito_ui")
    ),
    tabItem(tabName = "covid",
            h2("Impactos Sociais da COVID-19"),
            mod_indicadores_ui("covid_ui")
    )
  )
)

dashboardPage(header, sidebar, body, skin = "blue")
