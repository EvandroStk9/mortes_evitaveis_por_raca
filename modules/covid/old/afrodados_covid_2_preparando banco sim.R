###########################################################################
###########################################################################
###                                                                     ###
###                    Título: Preparando bancos SIM                    ###
###                                                                     ###
###########################################################################
###########################################################################

# Autor: Alexandre Silva Nogueira
# Data: 26/09/2022

#   1. Objetivo do script:

#   Este script prepara os bancos
#   de dados do SIM 2020 e 2021 para
#   as análises descritivas e de regressão.

#   2. Carregando pacotes:
library("pacman")
p_load(tidyverse, data.table, here, fs,
       lubridate, sf, geobr, googledrive,
       openxlsx, abjutils, sidrar,
       deflateBR, brazilmaps, lubridate)

options(scipen=999)
# drive_auth("gestao@ods-minas.page")

#   3. Criando pastas:
# setwd("C:\\Users\\alexandre pichilinga\\Documents\\1_afrodata\\covid\\scripts")
# dir_create(here(c("data",
#                   "documents",
#                   "scripts",
#                   "outputs",
#                   "old")))

dir_tree()

  # .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|           Abrindo bancos             |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

#   1. Abrindo SIM 2020 e SIM 2021:

# O banco foi baixado nos seguintes websites:
#    - https://dados.gov.br/dataset/sistema-de-informacao-sobre-mortalidade
#    - https://dados.gov.br/dataset/sistema-de-informacao-sobre-mortalidade-sim-1979-a-2018

# setwd("C:\\Users\\alexandre pichilinga\\Documents\\1_afrodata\\covid\\data")

library(here)

# sim_2020_raw <- fread("sim_preliminar_2020.csv")
# sim_2021_raw <- fread("DO21OPEN.csv")
sim_2020_raw <- fread(here("data", "sim_preliminar_2020.csv"))
sim_2021_raw <- fread(here("data", "DO21OPEN.csv"))

#   2. Abrindo bancos de CBO 2002:
# setwd("C:\\Users\\alexandre pichilinga\\Documents\\1_afrodata\\covid\\data\\cbo")

# cbo_grande_grupo <- fread("CBO2002 - Grande Grupo.csv", encoding = "Latin-1") %>%
#   transmute(id_cbo_1 = CODIGO, cbo_1 = TITULO)
# 
# cbo_subgrupo_principal <- fread("CBO2002 - SubGrupo Principal.csv", encoding = "Latin-1") %>%
#   transmute(id_cbo_2 = CODIGO, cbo_2 = TITULO)
# 
# cbo_ocup <- fread("CBO2002 - Ocupacao.csv", encoding = "Latin-1") %>%
#   transmute(id_cbo_6 = CODIGO, cbo_6 = TITULO)
# 
# cbo_familia <- fread("CBO2002 - Familia.csv", encoding = "Latin-1") %>%
#   transmute(id_cbo_4 = CODIGO, cbo_4 = TITULO)
# 
# cbo_subgrupo <- fread("CBO2002 - SubGrupo.csv", encoding = "Latin-1") %>%
#   transmute(id_cbo_3 = CODIGO, cbo_3 = TITULO)
# 
# cbo_familia_ajustada <- read.xlsx("cbo_ajust.xlsx") %>%
#   transmute(id_cbo_4,
#             id_cbo_4_agreg,
#             cbo_4_agreg,
#             grupo, hierarquia)

cbo_grande_grupo <- fread(here("data", "cbo", "CBO2002 - Grande Grupo.csv"), encoding = "Latin-1") %>%
  transmute(id_cbo_1 = CODIGO, cbo_1 = TITULO)

cbo_subgrupo_principal <- fread(here("data", "cbo", "CBO2002 - SubGrupo Principal.csv"), 
                                encoding = "Latin-1") %>%
  transmute(id_cbo_2 = CODIGO, cbo_2 = TITULO)

cbo_ocup <- fread(here("data", "cbo", "CBO2002 - Ocupacao.csv"), 
                  encoding = "Latin-1") %>%
  transmute(id_cbo_6 = CODIGO, cbo_6 = TITULO)

cbo_familia <- fread(here("data", "cbo", "CBO2002 - Familia.csv"), encoding = "Latin-1") %>%
  transmute(id_cbo_4 = CODIGO, cbo_4 = TITULO)

cbo_subgrupo <- fread(here("data", "cbo", "CBO2002 - SubGrupo.csv"), encoding = "Latin-1") %>%
  transmute(id_cbo_3 = CODIGO, cbo_3 = TITULO)

cbo_familia_ajustada <- read.xlsx(here("data", "cbo", "cbo_ajust.xlsx")) %>%
  transmute(id_cbo_4,
            id_cbo_4_agreg,
            cbo_4_agreg,
            grupo, hierarquia)

#   3. Abrindo bancos de Geo municípios + Geo Metropolitanas:
geo_municipios <- read_municipality(year = 2020)
geo_metropolitanas <- read_metro_area(year = 2018)

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|   Changing variables and adding CBO  |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# 1. Preparando banco sim 2020
sim_2020 <- sim_2020_raw %>%
  transmute(id_obito = as.character(contador),
            CODMUNRES,
            SEXO = case_when(SEXO == 1 ~ "Homem", SEXO == 2 ~ "Mulher"),
            RACACOR = case_when(RACACOR == 1 |
                                  RACACOR == 3 ~ "Branco ou Amarelo",
                                RACACOR == 2 | RACACOR == 4 ~ "Preto ou pardo",
                                RACACOR == 5 ~ "Indigena"),
            IDADE = as.integer(difftime(dmy(DTOBITO), dmy(DTNASC),
                                        units = "days")/365),
            ESC = case_when(ESC == 1 ~ "Nenhuma",
                            ESC == 2 ~ "1 a 3 anos de estudo",
                            ESC == 3 ~ "4 a 7 anos de estudo",
                            ESC == 4 ~ "8 a 11 anos de estudo",
                            ESC == 5 ~ "12 anos ou mais",
                            TRUE ~ "NA ou ignorado"),
            IDADE_FAIXA = case_when(IDADE>0  & IDADE<11  ~ "0 a 10 anos",
                                    IDADE>10 & IDADE<21 ~ "11 a 20 anos",
                                    IDADE>20 & IDADE<31 ~ "21 a 30 anos",
                                    IDADE>30 & IDADE<41 ~ "31 a 40 anos",
                                    IDADE>40 & IDADE<51 ~ "41 a 50 anos",
                                    IDADE>50 & IDADE<61 ~ "51 a 60 anos",
                                    IDADE>60 & IDADE<71 ~ "61 a 70 anos",
                                    IDADE>70 ~ "Mais de 70 anos"),
            PEA = if_else(IDADE >= 18 & IDADE < 65, 1, 0),
            COVID = if_else(CAUSABAS == "B342", 1, 0),
            id_cbo_6 = OCUP,
            ANO = 2020,
            DTOBITO,
            DATAOBITO = dmy(DTOBITO))

# 2. Preparando banco sim 2021
sim_2021 <- sim_2021_raw %>%
  transmute(id_obito = as.character(contador),
            CODMUNRES,
            SEXO = case_when(SEXO == 1 ~ "Homem", SEXO == 2 ~ "Mulher"),
            RACACOR = case_when(RACACOR == 1 |
                                  RACACOR == 3 ~ "Branco ou Amarelo",
                                RACACOR == 2 | RACACOR == 4 ~ "Preto ou pardo",
                                RACACOR == 5 ~ "Indigena"),
            IDADE = as.integer(difftime(dmy(DTOBITO), dmy(DTNASC),
                                        units = "days")/365),
            ESC = case_when(ESC == 1 ~ "Nenhuma",
                            ESC == 2 ~ "1 a 3 anos de estudo",
                            ESC == 3 ~ "4 a 7 anos de estudo",
                            ESC == 4 ~ "8 a 11 anos de estudo",
                            ESC == 5 ~ "12 anos ou mais",
                            TRUE ~ "NA ou ignorado"),
            IDADE_FAIXA = case_when(IDADE>0  & IDADE<11  ~ "0 a 10 anos",
                                    IDADE>10 & IDADE<21 ~ "11 a 20 anos",
                                    IDADE>20 & IDADE<31 ~ "21 a 30 anos",
                                    IDADE>30 & IDADE<41 ~ "31 a 40 anos",
                                    IDADE>40 & IDADE<51 ~ "41 a 50 anos",
                                    IDADE>50 & IDADE<61 ~ "51 a 60 anos",
                                    IDADE>60 & IDADE<71 ~ "61 a 70 anos",
                                    IDADE>70 ~ "Mais de 70 anos"),
            PEA = if_else(IDADE >= 18 & IDADE < 65, 1, 0),
            COVID = if_else(CAUSABAS == "B342", 1, 0),
            id_cbo_6 = OCUP,
            ANO = 2021,
            DTOBITO,
            DATAOBITO = dmy(DTOBITO))

# 3. Juntando bancos sim 2020 e 2021:
sim <- sim_2020 %>%
  bind_rows(sim_2021)

# 4. Adicionando informações ocupacionais:
sim <- sim %>%
  mutate(id_cbo_1 = as.numeric(str_sub(as.character(id_cbo_6), end = -6L)),
         id_cbo_2 = as.numeric(str_sub(as.character(id_cbo_6), end = -5L)),
         id_cbo_3 = as.numeric(str_sub(as.character(id_cbo_6), end = -4L)),
         id_cbo_4 = as.numeric(str_sub(as.character(id_cbo_6), end = -3L)),
         id_cbo_1 = ifelse(!is.na(id_cbo_6) & is.na(id_cbo_1), 0, id_cbo_1)) %>%
  left_join(cbo_ocup, by = "id_cbo_6") %>%
  left_join(cbo_familia, by = "id_cbo_4") %>%
  left_join(cbo_subgrupo, by = "id_cbo_3") %>%
  left_join(cbo_subgrupo_principal, by = "id_cbo_2") %>%
  left_join(cbo_grande_grupo, by = "id_cbo_1") %>%
  left_join(cbo_familia_ajustada, by = "id_cbo_4")

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|    Adding geografic informations     |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# 1. Informações geográficas:
geo <- geo_municipios %>%
  st_drop_geometry() %>%
  left_join(geo_metropolitanas %>%
              st_drop_geometry() %>%
              select(code_muni, name_metro), by = "code_muni") %>%
  transmute(code_muni,
            code_muni_6 = as.numeric(str_sub(as.character(code_muni),
                                             end = -2L)),
            name_muni,
            metro = case_when(!is.na(name_metro) ~ "Metropolitano",
                              TRUE ~ "Não Metropolitano"),
            name_metro, abbrev_state, name_region)

# Obs -> Duplicado: Município de Murici - AL em duas RM's (Zona da Mata e Maceió)
filter(geo_metropolitanas, duplicated(code_muni))

# 2. Retirando duplicado:
geo <- geo %>%
  filter(!c(code_muni == 2705507 & name_metro != "RM Maceió"))

filter(geo, duplicated(code_muni))


## Com o código abaixo vemos que a variável CODMUNRES é melhor para
## representar o município em que residia a pessoa morta.
sim_2021_raw %>%
  filter(CAUSABAS == "B342") %>% # Causa B342 = morte por Covid-19
  select(CODMUNOCOR, CODMUNRES) %>%
  summarize(across(everything(), n_distinct))

# 3. Adicionando informações geográficas:
sim <- sim %>%
  left_join(geo, by = c("CODMUNRES" = "code_muni_6")) %>% # Usando CODMUNRES
  select(-CODMUNRES)

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|  Separando População Econom. Ativa   |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# 1. Resumo de número de mortes segundo faixa etária
dados_gerais_banco_completo <- sim %>%
  group_by(COVID) %>%
  summarise(n_menos_18 = sum(IDADE < 18, na.rm = TRUE),
            n_pea = sum(IDADE >= 18 & IDADE < 65, na.rm = TRUE),
            n_mais_64 = sum(IDADE >= 65, na.rm = TRUE),
            n_missing_idade = sum(is.na(IDADE))) %>%
  mutate(total_na_coluna = n_menos_18 + n_pea + n_mais_64 + n_missing_idade)

# 2. Dividindo observações de interesse em objetos
pea_sim <- sim%>% # Banco apenas com casos em idade ativa
  filter(PEA == 1)

covid_sim <- sim %>%
  filter(COVID == 1) # Banco com casos cuja causa é covid

# 3. Resumo dos missings na população pea:
stats_pea <- pea_sim %>%
  summarize(across(everything(), ~ list(n = sum(!is.na(.)),
                                        n_distinct = n_distinct(.),
                                        Missing = sum(is.na(.)),
                                        Missing_prop = round(mean(is.na(.)), 2),
                                        Mean = round(mean(., na.rm = TRUE), 2))),
  Stat = c("N", "N_distinct", "Missing", "Missing_prop", "Mean")) %>%
  select(Stat, everything())

# 4.Proporção de mortes por ocupação (cbo_4) na pop pea:
perc_cbo_4 <- pea_sim %>%
  group_by(id_cbo_4, cbo_4) %>%
  summarize(n = n(),
            prop = n() / n_distinct(pea_sim$id_obito)) %>%
  ungroup() %>%
  arrange(desc(n))

# 5. NA id_cbo_4 vs NA nome cbo_4:
pea_sim %>%
  summarize(across(everything(), ~ mean(is.na(.)))) # 17.09% vs 45.56%

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|  Verificando ocup cbo_4 sem label    |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# 1.verificando NA's nos labels dos grupos CBO_4:
pea_sim %>%
  filter(is.na(cbo_4) & !is.na(id_cbo_4) & !is.na(id_cbo_3) & !is.na(id_cbo_6)) %>%
  summarize(unique(id_cbo_4))

# 1.1 Verificando NA's no CBO_4:
n_missing_cbo_4 <- pea_sim %>%
  group_by(id_cbo_6, id_cbo_4, cbo_4) %>%
  summarize(n = n()) %>%
  ungroup() %>%
  arrange(desc(id_cbo_6))

# Obs -> os CBO's 9999, 9989 e 2231 - Médicos estão sem labels.
# Obs -> Existem 211.992 casos com NA em CBO_4.
#        No banco de 2020 eram 99507 casos com NA em CBO_4.

## 9989-99 IGNORADO
## 9999-91 ESTUDANTE
## 9999-92 DONA DE CASA
## 9999-93 APOSENTADO/PENSIONISTA
## 9999-94 DESEMPREGADO CRONICO OU CUJA OCUPACAO HABITUAL NAO FOI POSSIVEL OBTER
## 9999-95 PRESIDIARIO (PESSOAS CONFINADAS EM INSTITUICOES PENAIS, INCLUSIVE MENORES DE IDADE)

# 2. Ajustando categorias no BD de PEA
pea_sim <- pea_sim %>%
  mutate(cbo_4 = case_when(id_cbo_4 %in% c(2231, 2251, 2252, 2253) ~ "Médicos",
                           id_cbo_4 == 9999 ~ "Inativos",
                           id_cbo_4 == 9989 ~ "Ignorado",
                           TRUE ~ cbo_4))

# 3. Calculando número de inativos, missings e ignorados em cbo_4:
resumo_pea_sim <- pea_sim %>%
  group_by(COVID) %>%
  summarise(n_inativos = sum(cbo_4=="Inativos", na.rm = TRUE),
            n_ignorados = sum(cbo_4=="Ignorado", na.rm = TRUE),
            n_aposentados = sum(id_cbo_6==999993, na.rm = TRUE),
            n_missing = sum(is.na(id_cbo_6)),
            n_nao_missing = sum(!is.na(id_cbo_6))) %>%
  mutate(total_missing_naomissing = n_missing + n_nao_missing,
         total_apos_inat_ign = n_aposentados + n_inativos + n_ignorados)

# 4. Retirando inativos, missings e ignorados em cbo_4 da base PEA:
pea_sim <- pea_sim %>%
  filter(!is.na(cbo_4) & cbo_4 != "Inativos" & cbo_4 != "Ignorado")

# Obs -> Com o filtro acima, a base foi de 1,24 milhões de casos para 676.485.


### Fazendo banco para calcular missings em raça e sexo
#pea_sim_nomissingocup <- pea_sim_2020 %>%
#  filter(!is.na(cbo_4) & cbo_4 != "Inativos" & cbo_4 != "Ignorado")
#
#pea_sim_nomissingocup %>%
#  group_by(COVID) %>%
#  summarise(n_sexo_missing = sum(is.na(SEXO)),
#            n_sexo_nomissing = sum(!is.na(SEXO)),
#            n_raca_missing = sum(is.na(RACACOR)),
#            n_raca_nomissing = sum(!is.na(RACACOR)))

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|Mudando vars também no banco covid_sim|##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# 1. Mudando vars no banco de covid_sim
covid_sim <- covid_sim %>%
  mutate(cbo_4 = case_when(id_cbo_4 %in% c(2231, 2251, 2252, 2253) ~ "Médicos",
                           id_cbo_4 == 9999 ~ "Inativos",
                           id_cbo_4 == 9989 ~ "Ignorado",
                           TRUE ~ cbo_4),
         PEA = case_when(!is.na(cbo_4) & cbo_4 != "Inativos" &
                           cbo_4 != "Ignorado" ~ 1,
                         TRUE ~ 0))

# 2. Resumindo dados de covid_sim:
covid_sim %>%
  summarize(na_cbo_4 = sum(is.na(cbo_4)),
            na_cbo_4_prop = mean(is.na(cbo_4)),
            cbo_4_ignorado = sum(cbo_4 == "Ignorado", na.rm = TRUE),
            cbo_4_ignorado_prop = mean(cbo_4 == "Ignorado", na.rm = TRUE),
            inativos = sum(cbo_4 == "Inativos", na.rm = TRUE),
            inativos_prop = mean(cbo_4 == "Inativos", na.rm = TRUE))

#    Obs:
# 86404 obitos com ocupação missing data (stricto sensu) nos dois anos, 13.71% - em 2020 era 31708, 15.3%.
# 13239 obitos de Ocupação Ignorada nos dois anos, 2.4% - em 2020 era 3851, 2.2%
# 251636 obitos de Inativos, 46.2% - em 2020 era 85991, 49.2%

# 3. Resumindo dados de pea_sim:
pea_sim %>%
  summarize(na_cbo_4 = sum(is.na(cbo_4)),
            na_cbo_4_prop = mean(is.na(cbo_4)),
            cbo_4_ignorado = sum(cbo_4 == "Ignorado", na.rm = TRUE),
            cbo_4_ignorado_prop = mean(cbo_4 == "Ignorado", na.rm = TRUE),
            inativos = sum(cbo_4 == "Inativos", na.rm = TRUE),
            inativos_prop = mean(cbo_4 == "Inativos", na.rm = TRUE))

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|  Resumindo dados de raça e educação  |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# 1. Óbitos por cor
pea_sim %>%
  group_by(RACACOR) %>%
  summarize(n = n(),
            prop = n() / n_distinct(pea_sim$id_obito)) %>%
  ungroup() %>%
  arrange(desc(n)) # Tem 1.5% de NA em raça

covid_sim %>%
  group_by(RACACOR) %>%
  summarize(n = n(),
            prop = n() / n_distinct(covid_sim$id_obito)) %>%
  ungroup() %>%
  arrange(desc(n)) # Tem 2.9% de NA em raça

# 2. Percentual de NA's por cor
covid_sim %>%
  summarize(na_cor = mean(is.na(RACACOR))) # 2.6%, em 2020 era 3.2%
pea_sim %>%
  summarize(na_cor = mean(is.na(RACACOR))) # 1.4%, em 2020 era 1.4%

# 3. Percentual de NA por escolaridade
covid_sim %>%
  summarize(sem_escolaridade = mean(ESC == "NA ou ignorado")) # 16.6%, em 2020 era 18.7%
pea_sim %>%
  summarize(sem_escolaridade = mean(ESC == "NA ou ignorado")) # 10.19%, em 2020 era 10.8%


# 4. NA escolaridade por ocupação
covid_sim %>%
  filter(ESC == "NA ou ignorado") %>%
  group_by(cbo_4) %>%
  summarize(n = n()) %>%
  arrange(desc(n))
pea_sim %>%
  filter(ESC == "NA ou ignorado") %>%
  group_by(cbo_4) %>%
  summarize(n = n()) %>%
  arrange(desc(n))

# 5. Perfil Geográfico
covid_sim %>%
  anti_join(geo_municipios %>% st_drop_geometry(), by = c("code_muni")) %>%
  count() # 143 óbitos sem cidade registrada, em 2020 eram 67

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|               Salvando               |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

# 1. Exportação
setwd("C:\\Users\\alexandre pichilinga\\Documents\\1_afrodata\\covid\\data")

saveRDS(sim, "sim_completo_2020e2021.RDS")
saveRDS(pea_sim, "pea_sim_2020e2021_preparado_para_regressao.RDS")

write.csv(sim, "sim_completo_2020e2021.csv")
write_csv(pea_sim, "pea_sim_2020e2021_preparado_para_regressao.csv")


#                 ~~~ Fim ~~~
