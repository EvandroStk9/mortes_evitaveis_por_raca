# Título: Rodando modelos de regressão            

# Autor: Alexandre Silva Nogueira e Evandro Luis Alves
# Data: 26/09/2022

#   1. Objetivo do script:

#   Este script roda os modelos de regressão
#   logística com os bancos sim 2020 e 2021
#   sobrepostos.


# 0. Setup ----------------------------------------------------------------

#   2. Carregando pacotes:
library("pacman")
p_load(tidyverse, tidylog, data.table, here, fs, arrow,
       lubridate, sf, geobr, openxlsx, broom)

options(scipen=999)

# 1. Importa --------------------------------------------------------------

#
pea_sim <- arrow::read_parquet(
  here("data", "sim", "sim.parquet")) %>%
  filter(PEA == 1)

# 2. Remodela os dados --------------------------------------------------------

# Retirando indígenas e missings em sexo do banco:
pea_sim_ajust <- pea_sim %>%
  #filter(ANO == 2020) %>%
  # filtrar de abril a setembro de 2020 e 2021. Filtrar também de abril a julho.
  filter(DATAOBITO>= "2021-04-01" & DATAOBITO < "2021-10-01") %>%
  filter(!is.na(SEXO) & RACACOR != "Indigena") %>%
  transmute(id_cbo_4,
            cbo_4,
            id_cbo_1,
            cbo_1 = str_to_sentence(cbo_1, locale = "br"),
            id_cbo_4_agreg,
            cbo_4_agreg,
            grupo,
            hierarquia,
            COVID = as.factor(COVID),
            IDADE = as.numeric(IDADE),
            # metro = as.factor(metro),
            SEXO = as.factor(SEXO),
            RACACOR = as.factor(RACACOR),
            DATAOBITO)

# 2. Olhando excluídos:
### 3989 observações num universo de 1240167 (0.3%)
pea_sim %>%
 count(is.na(SEXO), RACACOR == "Indigena") %>%
  mutate(prop = n/sum(n))


# Aninhando os dados por grande grupo ocupacional (grupo)
pea_sim_nested_grupo <- pea_sim_ajust %>%
  # group_by(hierarquia, grupo) %>%
  # ungroup() %>%
  nest(data = -c(hierarquia, grupo))

# Aninhando os dados por agregação de família ocupacional (CBO 4 dígitos ajustado)
pea_sim_nested_cbo_4_agreg <- pea_sim_ajust %>%
  # Necessário filtrar grupos que não tiveram pelo menos 2 categorias distintas
  group_by(id_cbo_4_agreg, cbo_4_agreg, hierarquia, grupo) %>%
  filter(n_distinct(SEXO) >= 2 & n_distinct(RACACOR) >= 2) %>%
  ungroup() %>%
  nest(data = -c(id_cbo_4_agreg, cbo_4_agreg, hierarquia, grupo)) 

# 3. Modela estratificado -------------------------------------------------


# Função para regressão logística estratificada por ocupação
get_modelo <- function(data) {
  glm(
    formula = COVID ~ IDADE + interaction(SEXO, RACACOR),
    # formula = COVID ~ IDADE + metro + interaction(SEXO, RACACOR),
      data = data,
      family = "binomial")
  }

# Modela e criando conjuntos de dados com razões de chance e IC's 
# Grande grupo ocupacional (CBO 1 dígito)
models_tidy_grupo <- pea_sim_nested_grupo %>%
  mutate(models = map(data, ~ get_modelo(.)),
         tidied = map(models, tidy)) %>%
  unnest(tidied) %>%
  select(-c(data, models)) %>%
  mutate(OR = exp(estimate),
         IC_inf = exp(estimate - 1.96 * std.error),
         IC_sup = exp(estimate + 1.96 * std.error)) ### IC de 5%

# Agegação de Família ocupacional (CBO 4 dígitos ajust)
models_tidy_cbo_4_agreg <- pea_sim_nested_cbo_4_agreg %>%
  mutate(models = map(data, ~ get_modelo(.)),
         tidied = map(models, tidy)) %>%
  unnest(tidied) %>%
  select(-c(data, models)) %>%
  mutate(OR = exp(estimate),
         IC_inf = exp(estimate - 1.96 * std.error),
         IC_sup = exp(estimate + 1.96 * std.error)) ### IC de 5%


# 5. Exporta --------------------------------------------------------------

#
fs::dir_create(
  here("data", "modelo")
)

#
arrow::write_parquet(
  models_tidy_cbo_4_agreg,
  here("data", "modelo", "modelo_ocupacao.parquet")
)

#
arrow::write_parquet(
  models_tidy_grupo,
  here("data", "modelo", "modelo_grupo.parquet")
)
