# Autor: Alexandre Silva Nogueira
# Data: 19/10/2022


# 0. Setup ----------------------------------------------------------------

#
library("pacman")
p_load(tidyverse, data.table, here, fs, lubridate, sf, arrow, 
       geobr, gt, ggrepel, ggthemes)

#
options(scipen=999)

# 1. Importa --------------------------------------------------------------

#
sim <- arrow::read_parquet(
  here("data", "sim", "sim.parquet")
)

#
pea_sim <- arrow::read_parquet(
  here("data", "sim", "pea_sim.parquet")
)

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|    2. Gráfico: mensal mortes covid   |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

pea_sim_2 <- pea_sim %>%
  mutate(
    mes = case_when(
      DATAOBITO >= "2020-01-01" & DATAOBITO < "2020-02-01" ~ "01 - Jan/2020",
      DATAOBITO >= "2020-02-01" & DATAOBITO < "2020-03-01" ~ "02 - Fev/2020",
      DATAOBITO >= "2020-03-01" & DATAOBITO < "2020-04-01" ~ "03 - Mar/2020",
      DATAOBITO >= "2020-04-01" & DATAOBITO < "2020-05-01" ~ "04 - Abr/2020",
      DATAOBITO >= "2020-05-01" & DATAOBITO < "2020-06-01" ~ "05 - Mai/2020",
      DATAOBITO >= "2020-06-01" & DATAOBITO < "2020-07-01" ~ "06 - Jun/2020",
      DATAOBITO >= "2020-07-01" & DATAOBITO < "2020-08-01" ~ "07 - Jul/2020",
      DATAOBITO >= "2020-08-01" & DATAOBITO < "2020-09-01" ~ "08 - Ago/2020",
      DATAOBITO >= "2020-09-01" & DATAOBITO < "2020-10-01" ~ "09 - Set/2020",
      DATAOBITO >= "2020-10-01" & DATAOBITO < "2020-11-01" ~ "10 - Out/2020",
      DATAOBITO >= "2020-11-01" & DATAOBITO < "2020-12-01" ~ "11 - Nov/2020",
      DATAOBITO >= "2020-12-01" & DATAOBITO < "2021-01-01" ~ "12 - Dez/2020",
      DATAOBITO >= "2021-01-01" & DATAOBITO < "2021-02-01" ~ "13 - Jan/2021",
      DATAOBITO >= "2021-02-01" & DATAOBITO < "2021-03-01" ~ "14 - Fev/2021",
      DATAOBITO >= "2021-03-01" & DATAOBITO < "2021-04-01" ~ "15 - Mar/2021",
      DATAOBITO >= "2021-04-01" & DATAOBITO < "2021-05-01" ~ "16 - Abr/2021",
      DATAOBITO >= "2021-05-01" & DATAOBITO < "2021-06-01" ~ "17 - Mai/2021",
      DATAOBITO >= "2021-06-01" & DATAOBITO < "2021-07-01" ~ "18 - Jun/2021",
      DATAOBITO >= "2021-07-01" & DATAOBITO < "2021-08-01" ~ "19 - Jul/2021",
      DATAOBITO >= "2021-08-01" & DATAOBITO < "2021-09-01" ~ "20 - Ago/2021",
      DATAOBITO >= "2021-09-01" & DATAOBITO < "2021-10-01" ~ "21 - Set/2021",
      DATAOBITO >= "2021-10-01" & DATAOBITO < "2021-11-01" ~ "22 - Out/2021",
      DATAOBITO >= "2021-11-01" & DATAOBITO < "2021-12-01" ~ "23 - Nov/2021",
      DATAOBITO >= "2021-12-01" & DATAOBITO <= "2021-12-31" ~ "24 - Dez/2021"),
    RACA_SEXO = case_when(SEXO == "Homem" & RACACOR == "Preto ou pardo" ~ "Preto ou pardo - Homem",
                          SEXO == "Homem" & RACACOR == "Branco ou Amarelo" ~ "Branco ou Amarelo - Homem",
                          SEXO == "Mulher" & RACACOR == "Preto ou pardo" ~ "Preto ou pardo - Mulher",
                          SEXO == "Mulher" & RACACOR == "Branco ou Amarelo" ~ "Branco ou Amarelo - Mulher")) %>%
  filter(!is.na(SEXO) & RACACOR != "Indigena")

pea_sim_3 <- pea_sim_2 %>%
  #group_by(mes, RACA_SEXO) %>%
  group_by(mes, RACACOR, SEXO) %>%
  summarise(proporcao = mean(COVID),
            n_mortes = n(),
            n_mortes_covid = sum(COVID==1),
            proporcao_2 = n_mortes_covid/n_mortes)

# Coferindo totais e proporções:
pea_sim_3 %>%
  summarise(n_mortes = sum(n_mortes),
            n_mortes_covid = sum(n_mortes_covid)) %>%
  summarise(n_mortes = sum(n_mortes),
            n_mortes_covid = sum(n_mortes_covid))

pea_sim_2 %>%
  filter(COVID==1) %>%
  summarise(n = n())

# Construindo gráfico de mortes por mês:
pea_sim_3 %>%
  ggplot(aes(mes, proporcao*100)) +
  geom_bar(stat = "identity", position = "dodge", colour="black", fill="#DD8888", width=.8) +
  facet_grid(vars(SEXO), vars(RACACOR)) +
  #facet_wrap(~RACA_SEXO, ncol=1) +
  #geom_text(aes(label = round(propo, 2)), position = position_dodge(width = 0.9), vjust = -1) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 80, vjust = 0.5, hjust=0.5),
        axis.title.x=element_blank(),
        axis.title.y=element_text(size = 13.5, face = "bold"),
        #axis.ticks.x=element_blank(),
        strip.background = element_rect(colour="black", fill="azure2",
                                        size=0.5, linetype="solid"),
        strip.text.x = element_text(size=12, color="black",
                                    face="bold"),
        strip.text.y = element_text(size=12, color="black",
                                    face="bold")) +
  ylab("% de mortes por covid")

# Salvando tabela para fazer gráfico mensal:
setwd("C:\\Users\\alexandre pichilinga\\Documents\\1_afrodata\\covid\\outputs")

write.xlsx(pea_sim_3, "pea_sim_agrupado por mes e sexoraca_filtro de indigenas e missing em sexo.xlsx")

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|    2. Gráfico: mensal mortes covid   |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

setwd("C:\\Users\\alexandre pichilinga\\Documents\\1_afrodata\\covid\\data")
pea_sim_rogerio <- read.xlsx(
  "pea_sim_agrupado por mes e sexoraca_filtro de indigenas e missing em sexo_revROGERIOBarbosa.xlsx", 
  sheet = 3)

pea_sim_rogerio %>%
  rename(hb_mn = `HB-MN`) %>%
  ggplot(aes(y=hb_mn, x=`mês`)) +
  geom_bar(position="stack", stat="identity", colour="black", fill="#DD8888", width=.8) +
  theme_minimal() +
  labs(title = "% de chance de morrer por covid-19 de Homens Brancos \nem relação a Mulheres Pretas") +
  ylab("% de chance de morrer por covid") +
  theme(axis.text.x = element_text(angle = 80, vjust = 0.5, hjust=0.5),
        axis.text.y = element_text(vjust = 0.5, hjust=0.5, size = 11),
        axis.title.x=element_blank(),
        axis.title.y=element_text(size = 14, face = "bold", vjust = 2),
        plot.title = element_text(size = 16))

pea_sim_rogerio %>%
  rename(hn_mn = `HN-MN`) %>%
  ggplot(aes(y=hn_mn, x=`mês`)) +
  geom_bar(position="stack", stat="identity", colour="black", fill="#DD8888", width=.8) +
  theme_minimal() +
  labs(title = "% de chance de morrer por covid-19 de Homens Pretos \nem relação a Mulheres Pretas") +
  ylab("% de chance de morrer por covid") +
  theme(axis.text.x = element_text(angle = 80, vjust = 0.5, hjust=0.5),
        axis.text.y = element_text(vjust = 0.5, hjust=0.5, size = 11),
        axis.title.x=element_blank(),
        axis.title.y=element_text(size = 14, face = "bold", vjust = 2),
        plot.title = element_text(size = 16))

# mulheres brancas
pea_sim_rogerio %>%
  rename(mb_mn = `MB-MN`) %>%
  ggplot(aes(y=mb_mn, x=`mês`)) +
  geom_bar(position="stack", stat="identity", colour="black", fill="#DD8888", width=.8) +
  theme_minimal() +
  labs(title = "% de chance de morrer por covid-19 de Mulheres Brancas \nem relação a Mulheres Pretas") +
  ylab("% de chance de morrer por covid") +
  theme(axis.text.x = element_text(angle = 80, vjust = 0.5, hjust=0.5),
        axis.text.y = element_text(vjust = 0.5, hjust=0.5, size = 11),
        axis.title.x=element_blank(),
        axis.title.y=element_text(size = 14, face = "bold", vjust = 2),
        plot.title = element_text(size = 16))

#                                      ~~~~~ Fim ~~~~~
