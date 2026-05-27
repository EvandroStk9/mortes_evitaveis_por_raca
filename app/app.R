# app/app.R
# Dashboard de Mortes Evitáveis por Raça/Cor
library(shiny)
library(shinydashboard)
library(tidyverse)
library(arrow)
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
        column(3, selectInput(ns("sexo"), "Filtrar por Sexo:", 
                              choices = c("Todos", "Masculino", "Feminino"), selected = "Todos")),
        column(3, selectInput(ns("causa"), "Causa do Óbito (CID):", 
                              choices = "Todos", selected = "Todos")),
        column(6, uiOutput(ns("year_selector")))
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
    ns <- session$ns
    
    # Carregamento de dados brutos do módulo
    raw_data <- reactive({
      path <- file.path("data", file_name)
      req(file.exists(path))
      read_parquet(path)
    })
    
    # UI Dinâmica para o seletor de anos
    output$year_selector <- renderUI({
      df <- raw_data()
      min_year <- min(df$ano, na.rm = TRUE)
      max_year <- max(df$ano, na.rm = TRUE)
      
      sliderInput(ns("anos"), "Série Histórica (Anos):",
                  min = min_year, max = max_year,
                  value = c(min_year, max_year),
                  step = 1, sep = "")
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
      req(input$anos)
      
      df <- df %>%
        filter(ano >= input$anos[1], ano <= input$anos[2])
      
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
    
    # Função auxiliar para gerar marcas do eixo X (limpa a poluição visual)
    get_x_axis_labels <- function(df) {
      df %>%
        mutate(ano_label = substr(ano_trimestre, 1, 4)) %>%
        group_by(ano_label) %>%
        summarise(break_val = min(ano_trimestre), .groups = "drop")
    }
    
    # 1) Gráfico de Linhas (Absoluto)
    output$plot_line <- renderPlotly({
      df <- data_filtered()
      req(nrow(df) > 0)
      
      eixo_x <- get_x_axis_labels(df)
      
      p <- ggplot(df, aes(x = ano_trimestre, y = total, color = raca_agreg, group = raca_agreg,
                          text = paste0("Trimestre: ", ano_trimestre, 
                                        "<br>Raça: ", raca_agreg, 
                                        "<br>Óbitos: ", total))) +
        geom_line(size = 1) +
        geom_point(size = 2) +
        scale_color_manual(values = PALETA_RACA) +
        scale_x_discrete(breaks = eixo_x$break_val, labels = eixo_x$ano_label) +
        theme_minimal() +
        labs(x = "Ano", y = "Número de Óbitos", color = "Raça/Cor")
      
      ggplotly(p, tooltip = "text") %>% layout(legend = list(orientation = "h", y = -0.2))
    })
    
    # 2) Gráfico de Barras Stack (Percentual)
    output$plot_percent <- renderPlotly({
      df <- data_filtered()
      req(nrow(df) > 0)
      
      eixo_x <- get_x_axis_labels(df)
      
      df <- df %>%
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
        scale_x_discrete(breaks = eixo_x$break_val, labels = eixo_x$ano_label) +
        theme_minimal() +
        labs(x = "Ano", y = "Proporção de Óbitos", fill = "Raça/Cor")
      
      ggplotly(p, tooltip = "text") %>% layout(legend = list(orientation = "h", y = -0.2))
    })
  })
}

# --- Dashboard Principal ---

# Carrega metadados para gerar UI dinâmica
metadata_files <- list.files("metadata", pattern = "\\.yaml$", full.names = TRUE)
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
