# main.R
# Ponto de entrada consolidado: Análise COVID (com Raça/Cor) e Trânsito

# 1. Dependências
deps <- c("tidyverse", "arrow", "janitor", "here", "shiny", "shinydashboard", "plotly", "openxlsx")
new_deps <- deps[!(deps %in% installed.packages()[,"Package"])]
if(length(new_deps) > 0) install.packages(new_deps, repos = "https://cloud.r-project.org")

library(tidyverse); library(arrow); library(janitor); library(here); library(shiny); library(shinydashboard); library(plotly); library(openxlsx)

# 2. ETL COVID (Foco em Raça/Cor)
message("Processando base COVID...")
# Verifica existência do arquivo em data/raw/covid/sim.parquet
path_covid <- here("data/raw/covid/sim.parquet")
if(file.exists(path_covid)) {
  df_covid <- read_parquet(path_covid) %>%
    janitor::clean_names() %>%
    mutate(
      raca_label = case_when(
        racacor == 1 ~ "Branca",
        racacor == 2 ~ "Preta",
        racacor == 4 ~ "Parda",
        TRUE ~ "Outros/Ignorado"
      ),
      ano = substr(as.character(dtobito), 7, 10) # Ajuste conforme formato da data real
    )
} else {
  df_covid <- tibble(ano = NA, raca_label = "Base não encontrada", total = 0)
  message("Aviso: Arquivo COVID não encontrado em data/raw/covid/sim.parquet")
}

# 3. ETL Trânsito (Foco em Tendência)
message("Processando base Trânsito...")
files <- list.files(here("data/raw/transito"), pattern = "*.parquet", full.names = TRUE)
if(length(files) > 0) {
  df_transito <- map_dfr(files, read_parquet) %>%
    janitor::clean_names() %>%
    mutate(
      ano = substr(as.character(data_obito_raw), 5, 8),
      mes = substr(as.character(data_obito_raw), 3, 4),
      ano_trimestre = paste0(ano, "-", case_when(mes %in% c("01","02","03") ~ "03", mes %in% c("04","05","06") ~ "06", mes %in% c("07","08","09") ~ "09", TRUE ~ "12"))
    )
} else {
  df_transito <- tibble(ano_trimestre = NA, total = 0)
}

# 4. Dashboard Interativo
ui <- dashboardPage(
  dashboardHeader(title = "Plataforma CEBRAP"),
  dashboardSidebar(sidebarMenu(
    menuItem("COVID-19 (Análise Racial)", tabName = "covid"),
    menuItem("Trânsito (Tendência)", tabName = "transito")
  )),
  dashboardBody(tabItems(
    tabItem(tabName = "covid", 
            box(width = 12, title = "Óbitos por COVID-19 segundo Raça/Cor", status = "danger", solidHeader = TRUE,
                plotlyOutput("plot_covid"))),
    tabItem(tabName = "transito", 
            box(width = 12, title = "Tendência de Óbitos no Trânsito", status = "primary", solidHeader = TRUE,
                plotlyOutput("plot_transito")))
  ))
)

server <- function(input, output) {
  output$plot_covid <- renderPlotly({
    req(exists("df_covid") && "raca_label" %in% names(df_covid))
    p <- df_covid %>%
      filter(covid == 1) %>%
      group_by(ano, raca_label) %>%
      summarise(total = n(), .groups="drop") %>%
      ggplot(aes(x = ano, y = total, fill = raca_label, text = paste("Raça:", raca_label, "<br>Total:", total))) +
      geom_col(position = "stack") + theme_minimal() + labs(x="Ano", y="Óbitos", fill="Raça/Cor")
    ggplotly(p, tooltip="text")
  })
  
  output$plot_transito <- renderPlotly({
    req(exists("df_transito"))
    p <- df_transito %>%
      group_by(ano_trimestre) %>%
      summarise(total = n(), .groups="drop") %>%
      ggplot(aes(x = ano_trimestre, y = total, text = paste("Trimestre:", ano_trimestre, "<br>Óbitos:", total))) +
      geom_col(fill = "#1B4F72") + theme_minimal() + labs(x="Período", y="Óbitos") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggplotly(p, tooltip="text")
  })
}

shinyApp(ui, server)
