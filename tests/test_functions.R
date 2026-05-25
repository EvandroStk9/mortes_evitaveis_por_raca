# tests/test_functions.R
library(testthat)

test_that("Cálculo de taxa de mortalidade está correto", {
  expect_equal(calculate_mortality_rate(10, 100000), 10)
  expect_equal(calculate_mortality_rate(5, 50000), 10)
})

test_that("Padronização de raça funciona para categorias IBGE", {
  df <- tibble(racacor = c(1, 2, 4))
  df_std <- standardize_race_groups(df)
  
  expect_true("Branca" %in% df_std$raca_cor_ibge)
  expect_true("Negra" %in% df_std$raca_cor_agreg)
})
