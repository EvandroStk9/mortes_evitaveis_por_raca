library(jsonvalidate)
library(yaml)
library(here)
library(jsonlite)
library(purrr)

validate_module <- function(yaml_file) {
  schema <- here("metadata/schema.json")
  data <- yaml::read_yaml(yaml_file)
  
  # Validação
  result <- jsonvalidate::json_validate(
    jsonlite::toJSON(data, auto_unbox = TRUE), 
    schema, 
    verbose = TRUE,
    engine = "ajv"
  )
  
  if (!result) {
    stop("Erro de validação em ", yaml_file, ":
", paste(attr(result, "errors")$message, collapse = "
"))
  }
  message("Módulo ", data$id, " validado com sucesso.")
}

# Valida todos
yaml_files <- list.files(here("metadata"), "*.yaml", full.names = TRUE)
walk(yaml_files, validate_module)
