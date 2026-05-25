# apps/plataforma_monitoramento/app.R
# App Shiny Simplificado - Sem dependências externas de módulos
library(shiny)
library(tidyverse)
library(arrow)
library(here)

# Lê o dado processado
df <- read_parquet(here("dados_finais.parquet"))

ui <- fluidPage(
  titlePanel("Monitoramento de Óbitos (Trânsito)"),
  plotOutput("grafico", height = "500px")
)

server <- function(input, output) {
  output$grafico <- renderPlot({
    df %>% 
      ggplot(aes(x = ano_trimestre, y = total)) +
      geom_col(fill = "#1B4F72") +
      theme_minimal() +
      labs(title = "Óbitos por Trimestre", x = "Período (Ano-Mês)", y = "Total de Óbitos") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
}

shinyApp(ui, server)
