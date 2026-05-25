# Título: Preparando bancos SIM

# Autor: Alexandre Silva Nogueira
# Data: 26/09/2022

# Objetivo do script:
# Este script prepara os dados do SIM 2020/21 para AED e regressão logística

# 0. Setup --------------------------------------------------------------------

# Carrega pacotes
library("pacman")
p_load(tidyverse, data.table, here, fs, lubridate, sf, arrow, 
       geobr, openxlsx)

# Opções
options(scipen=999)


# 1. Importa --------------------------------------------------------------

# A - SIM

# O banco foi baixado nos seguintes websites:
#    - https://dados.gov.br/dataset/sistema-de-informacao-sobre-mortalidade
#    - https://dados.gov.br/dataset/sistema-de-informacao-sobre-mortalidade-sim-1979-a-2018
sim_2020_raw <- fread(here("data", "raw", "sim", 
                           "sim_preliminar_2020.csv"))
sim_2021_raw <- fread(here("data", "raw", "sim", 
                           "DO21OPEN.csv"))

# B - CBO 2002

#
cbo_grande_grupo <- fread(here("data", "raw", "cbo", 
                               "CBO2002 - Grande Grupo.csv"), 
                          encoding = "Latin-1") %>%
  transmute(id_cbo_1 = CODIGO, cbo_1 = TITULO)

#
cbo_subgrupo_principal <- fread(here("data", "raw", "cbo", 
                                     "CBO2002 - SubGrupo Principal.csv"), 
                                encoding = "Latin-1") %>%
  transmute(id_cbo_2 = CODIGO, cbo_2 = TITULO)

#
cbo_ocup <- fread(here("data", "raw", "cbo", 
                       "CBO2002 - Ocupacao.csv"), 
                  encoding = "Latin-1") %>%
  transmute(id_cbo_6 = CODIGO, cbo_6 = TITULO)

#
cbo_familia <- fread(here("data", "raw", "cbo", 
                          "CBO2002 - Familia.csv"), encoding = "Latin-1") %>%
  transmute(id_cbo_4 = CODIGO, cbo_4 = TITULO)

#
cbo_subgrupo <- fread(here("data", "raw", "cbo", 
                           "CBO2002 - SubGrupo.csv"), encoding = "Latin-1") %>%
  transmute(id_cbo_3 = CODIGO, cbo_3 = TITULO)


# 2. Integra dados --------------------------------------------------------

# Tipologia para agregação de CBO's
tipologia_cbo <- read.xlsx(here("data", "cbo", 
                                       "tipologia_cbo.xlsx")) %>%
  transmute(id_cbo_4,
            id_cbo_4_agreg,
            cbo_4_agreg,
            grupo, hierarquia)

# Informações Geográficas

# Abrindo bancos de Geo municípios + Geo Metropolitanas:
geo_municipios <- read_municipality(year = 2020)
geo_metropolitanas <- read_metro_area(year = 2018)

# 3. Remodela os dados ---------------------------------------------------------

# Preparando banco sim 2020-2021
sim_no_geo <- map_df(
  list(sim_2020_raw, sim_2021_raw),
  ~ .x %>%
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
              DTOBITO,
              DATAOBITO = dmy(DTOBITO),
              ANO = year(DATAOBITO))
  ) %>%
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
  left_join(tipologia_cbo, by = "id_cbo_4")


# Obs -> Duplicado: Município de Murici - AL em duas RM's (Zona da Mata e Maceió)
filter(geo_metropolitanas, duplicated(code_muni))

# Informações geográficas
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
            name_metro, abbrev_state, name_region) %>%
  # Remove duplicata
  filter(!c(code_muni == 2705507 & name_metro != "RM Maceió"))


## A variável CODMUNRES é melhor chave relacional
## Para representar o município em que residia a pessoa morta
sim_2021_raw %>%
  filter(CAUSABAS == "B342") %>% # Causa B342 = morte por Covid-19
  select(CODMUNOCOR, CODMUNRES) %>%
  summarize(across(everything(), n_distinct))

# Adicionando informações geográficas
sim <- sim_no_geo %>%
  left_join(geo, by = c("CODMUNRES" = "code_muni_6")) %>% # Usando CODMUNRES
  select(-CODMUNRES)


# 4. Ajusta dados CBO 2002 ----------------------------------------------------

# NA id_cbo_4 vs NA nome cbo_4:
sim %>%
  filter(PEA == 1) %>%
  summarize(across(everything(), ~ mean(is.na(.)))) %>% 
  glimpse() # 17.09% vs 45.56%

# Verificando NA's nos labels dos grupos CBO_4
sim %>%
  filter(PEA == 1) %>%
  filter(is.na(cbo_4) & !is.na(id_cbo_4) & !is.na(id_cbo_3) & !is.na(id_cbo_6)) %>%
  summarize(unique(id_cbo_4))

# Verificando NA's no CBO_4:
n_missing_cbo_4 <- sim %>%
  filter(PEA == 1) %>%
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

#
sim %>%
  filter(PEA == 1) %>%
  summarize(na_cbo_4 = sum(is.na(cbo_4)),
            na_cbo_4_prop = mean(is.na(cbo_4)),
            cbo_4_ignorado = sum(cbo_4 == "Ignorado", na.rm = TRUE),
            cbo_4_ignorado_prop = mean(cbo_4 == "Ignorado", na.rm = TRUE),
            inativos = sum(cbo_4 == "Inativos", na.rm = TRUE),
            inativos_prop = mean(cbo_4 == "Inativos", na.rm = TRUE))


# Calculando número de inativos, missings e ignorados em cbo_4:
resumo_pea_sim <- sim %>%
  filter(PEA == 1) %>%
  group_by(COVID) %>%
  summarise(n_inativos = sum(cbo_4=="Inativos", na.rm = TRUE),
            n_ignorados = sum(cbo_4=="Ignorado", na.rm = TRUE),
            n_aposentados = sum(id_cbo_6==999993, na.rm = TRUE),
            n_missing = sum(is.na(id_cbo_6)),
            n_nao_missing = sum(!is.na(id_cbo_6))) %>%
  mutate(total_missing_naomissing = n_missing + n_nao_missing,
         total_apos_inat_ign = n_aposentados + n_inativos + n_ignorados)



# Retirando inativos, missings e ignorados em cbo_4 da base PEA:
sim_ajust <- sim %>%
  filter(PEA == 1) %>%
  mutate(cbo_4 = case_when(id_cbo_4 %in% c(2231, 2251, 2252, 2253) ~ "Médicos",
                           id_cbo_4 == 9999 ~ "Inativos",
                           id_cbo_4 == 9989 ~ "Ignorado",
                           TRUE ~ cbo_4)) %>%
  filter(!is.na(cbo_4) & cbo_4 != "Inativos" & cbo_4 != "Ignorado")

# Obs -> Com o filtro acima, a base foi de 1,24 milhões de casos para 675.080

# 5. Exporta --------------------------------------------------------------

#
fs::dir_create(here("data", "sim"))

#
arrow::write_parquet(
  sim, 
  here("data", "sim", "sim.parquet")
)


