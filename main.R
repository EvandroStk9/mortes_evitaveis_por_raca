library(here)
library(rsconnect)

source(here("src/01_ingest.R"))
source(here("src/02_etl.R"))
source(here("src/03_modules_gen.R"))
shiny::runApp(here("app/app.R"))
