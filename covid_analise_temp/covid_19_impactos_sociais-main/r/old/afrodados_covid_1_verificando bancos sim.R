###########################################################################
###########################################################################
###                                                                     ###
###                    Título: Verificação das bases                    ###
###                    de dados do SIM 2020 e 2021                      ###
###                                                                     ###
###########################################################################
###########################################################################

# Autor: Alexandre Silva Nogueira
# Data: 13/09/2022

#   (1) Objetivo do script:

#   Este script faz uma análise das variáveis
#   do banco SIM de 2020 e 2021, para averiguar
#   se elas estão normalizadas.

#   (2) Carregando pacotes:
library("pacman")
p_load(tidyverse, data.table, here, fs,
       lubridate, sf, geobr, googledrive,
       openxlsx, abjutils, sidrar,
       deflateBR, brazilmaps, naniar)

options(scipen=999) # Evita aparecerem notações científicas nas tabelas

library(here)

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|           Abrindo bancos             |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# setwd("C:\\Users\\alexandre pichilinga\\Documents\\1_afrodata\\covid\\data")

# sim2020 <- fread("sim_preliminar_2020.csv")
# sim2021 <- fread("DO21OPEN.csv")
# sim2019 <- fread("Mortalidade_Geral_2019.csv")

sim2020 <- fread(here("data", "sim_preliminar_2020.csv"))
sim2021 <- fread(here("data", "DO21OPEN.csv"))
sim2019 <- fread(here("data", "Mortalidade_Geral_2019.csv"))

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|           Analisando bancos          |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# 1. Verificando se os bancos possuem as mesmas variáveis:
var20 <- as.data.frame(names(sim2020))
var21 <- as.data.frame(names(sim2021))
var19 <- as.data.frame(names(sim2019))

# 1.1 - Verificando bancos 2019 e 2020:
var19_2 <- var19 %>%
  rename(var = `names(sim2019)`) %>%
  mutate(varteste = "teste")

var_20_19 <- var20 %>%
  mutate(var = toupper(`names(sim2020)`)) %>%
  left_join(var19_2, by="var")

   # Existem 84 variáveis em comum. Faltam 4 variáveis,
   # 1 delas está em 2020 mas não está em 2019. Essa variável é
   # OPOR_DO. Ela não existia antes de 2020.

var_sobrando_2019 <- var19_2 %>%
  anti_join(var_20_19, by="var")

   # Por outro lado, são 4 variáveis que existem em 2019 mas não
   # existem em 2020. Elas são: NUDIASINF, FONTESINF, NUDIASOBIN,
   # ESTABDESCR.

# 1.2 Verificando bancos 2020 e 2021:
tab_final <- var21 %>%
    bind_cols(var20) %>%
  mutate(igual = ifelse("names(sim2019)" == "names(sim2020)", TRUE, FALSE))


# 2. Verificando a quantidade de missings:

# 2.1 - Adicionando variável que falta em 2019:
sim2019 <- sim2019 %>%
  mutate(TP_ALTERA = NA_real_)

# 2.2 - Adicionando variáiveis que faltam em 2020:
sim2020 <- sim2020 %>%
  mutate(NUDIASINF = NA_real_,
         FONTESINF = NA_real_,
         NUDIASOBIN = NA_real_,
         ESTABDESCR = NA_real_)

# 2.3 - Usando pacote naniar para ver missings:
na2020 <- miss_var_summary(sim2020)
na2021 <- miss_var_summary(sim2021)
na2019 <- miss_var_summary(sim2019)

# 2.2 - Analisando missings entre 2020 e 2021:
missing <- left_join(na2020, na2021, by="variable")

missing2 <- missing %>%
  mutate(diferenca = pct_miss.x - pct_miss.y)

# 2.3 - Analisando missings entre 2019 e 2020:
missing <- left_join(na2019, na2020, by="variable")

missing3 <- missing %>%
  mutate(diferenca = pct_miss.x - pct_miss.y)

#                                      ~~~~~ Fim ~~~~~

