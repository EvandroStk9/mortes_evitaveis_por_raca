# apps/plataforma_monitoramento/ui.R
library(shiny)
library(shinydashboard)

header <- dashboardHeader(
  title = "Painel Institucional CEBRAP", 
  titleWidth = 300
)

sidebar <- dashboardSidebar(
  width = 300,
  sidebarMenu(
    menuItem("Vis\u00e3o Geral", tabName = "geral", icon = icon("globe-americas")),
    menuItem("Mortes no Tr\u00e2nsito", tabName = "transito_std", icon = icon("car")),
    menuItem("COVID-19", tabName = "covid_std", icon = icon("virus")),
    menuItem("Hist\u00f3rico (Fidelidade)", icon = icon("history"),
             menuSubItem("Tr\u00e2nsito Original", tabName = "transito_orig"),
             menuSubItem("COVID Original", tabName = "covid_orig")),
    menuItem("Metodologia", tabName = "metodo", icon = icon("book"))
  )
)

body <- dashboardBody(
  tags$head(
    tags$style(HTML("
      .content-wrapper { background-color: #f4f6f9; }
      .main-header .logo { font-weight: bold; font-size: 18px; }
      .box-title { font-weight: bold; }
    "))
  ),
  tabItems(
    # Aba Padronizada: Trânsito
    tabItem(tabName = "transito_std",
            mod_standard_ui("transito_std", label = "Tr\u00e2nsito")
    ),
    
    # Aba Padronizada: COVID
    tabItem(tabName = "covid_std",
            mod_standard_ui("covid_std", label = "COVID-19")
    ),
    
    # Abas Originais (Mantidas para referência)
    tabItem(tabName = "transito_orig", mod_indicadores_ui("transito_ui")),
    tabItem(tabName = "covid_orig", mod_covid_ui("covid_ui"))
  )
)

dashboardPage(header, sidebar, body, skin = "black")
