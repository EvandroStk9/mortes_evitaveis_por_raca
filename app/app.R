# app/app.R
# Dashboard de Mortes Evitáveis por Raça/Cor
library(shiny)
library(shinydashboard)
library(tidyverse)
library(arrow)
library(here)
library(plotly)
library(yaml)

# --- Configurações Visuais ---
PALETA_RACA <- c(
  "Preto ou Pardo" = "#8c510a",
  "Branco ou Amarelo" = "#dfc27d",
  "Indígena" = "#01665e",
  "Ignorado/NI" = "#969696"
)

# --- Módulo Shiny: Visualização de Óbitos ---
death_module_ui <- function(id, label) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = paste("Filtros -", label), width = 12, status = "primary", solidHeader = TRUE,
        column(4, selectInput(ns("sexo"), "Filtrar por Sexo:", 
                              choices = c("Todos", "Masculino", "Feminino"), selected = "Todos")),
        column(4, selectInput(ns("causa"), "Causa do Óbito (CID):", 
                              choices = "Todos", selected = "Todos"))
      )
    ),
    fluidRow(
      box(
        title = "Tendência de Óbitos (Número Absoluto)", width = 12, status = "info",
        plotlyOutput(ns("plot_line"))
      )
    ),
    fluidRow(
      box(
        title = "Composição por Raça/Cor (Percentual)", width = 12, status = "info",
        plotlyOutput(ns("plot_percent"))
      )
    )
  )
}

death_module_server <- function(id, file_name) {
  moduleServer(id, function(input, output, session) {
    
    # Carregamento de dados brutos do módulo
    raw_data <- reactive({
      path <- file.path("data", file_name)
      req(file.exists(path))
      read_parquet(path)
    })
    
    # Atualiza dinamicamente as opções de CID baseadas no arquivo carregado
    observe({
      df <- raw_data()
      cids <- sort(unique(df$causabas))
      updateSelectInput(session, "causa", choices = c("Todos", cids), selected = "Todos")
    })
    
    # Filtragem reativa
    data_filtered <- reactive({
      df <- raw_data()
      
      if (input$sexo != "Todos") {
        df <- df %>% filter(sexo == input$sexo)
      }
      
      if (input$causa != "Todos") {
        df <- df %>% filter(causabas == input$causa)
      }
      
      # Agrega por trimestre e raça após filtros
      df %>%
        group_by(ano_trimestre, raca_agreg) %>%
        summarise(total = sum(total), .groups = "drop")
    })
    
    # 1) Gráfico de Linhas (Absoluto)
    output$plot_line <- renderPlotly({
      df <- data_filtered()
      
      p <- ggplot(df, aes(x = ano_trimestre, y = total, color = raca_agreg, group = raca_agreg,
                          text = paste0("Trimestre: ", ano_trimestre, 
                                        "<br>Raça: ", raca_agreg, 
                                        "<br>Óbitos: ", total))) +
        geom_line(size = 1) +
        geom_point(size = 2) +
        scale_color_manual(values = PALETA_RACA) +
        theme_minimal() +
        labs(x = "Ano-Trimestre", y = "Número de Óbitos", color = "Raça/Cor")
      
      ggplotly(p, tooltip = "text") %>% layout(legend = list(orientation = "h", y = -0.2))
    })
    
    # 2) Gráfico de Barras Stack (Percentual)
    output$plot_percent <- renderPlotly({
      df <- data_filtered() %>%
        group_by(ano_trimestre) %>%
        mutate(
          total_periodo = sum(total),
          pct = total / total_periodo,
          label_pct = scales::percent(pct, accuracy = 0.1)
        ) %>%
        ungroup()
      
      p <- ggplot(df, aes(x = ano_trimestre, y = total, fill = raca_agreg,
                          text = paste0("Trimestre: ", ano_trimestre, 
                                        "<br>Raça: ", raca_agreg, 
                                        "<br>Óbitos: ", total,
                                        "<br>Percentual: ", label_pct))) +
        geom_col(position = "fill") +
        scale_fill_manual(values = PALETA_RACA) +
        scale_y_continuous(labels = scales::percent) +
        theme_minimal() +
        labs(x = "Ano-Trimestre", y = "Proporção de Óbitos", fill = "Raça/Cor")
      
      ggplotly(p, tooltip = "text") %>% layout(legend = list(orientation = "h", y = -0.2))
    })
  })
}

# --- Dashboard Principal ---

# Carrega metadados para gerar UI dinâmica
metadata_files <- list.files(here("metadata"), pattern = "\\.yaml$", full.names = TRUE)
metadata_list <- map(metadata_files, yaml::read_yaml)

ui <- dashboardPage(
  dashboardHeader(title = "Mortes Evitáveis"),
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      map(metadata_list, ~ menuItem(.x$nome, tabName = .x$id))
    )
  ),
  dashboardBody(
    do.call(tabItems, map(metadata_list, ~ {
      tabItem(tabName = .x$id, death_module_ui(.x$id, .x$nome))
    }))
  )
)

server <- function(input, output, session) {
  # Inicializa servidores dos módulos dinamicamente
  walk(metadata_list, ~ {
    death_module_server(.x$id, paste0(.x$id, ".parquet"))
  })
}

shinyApp(ui, server)
