library("pacman")
p_load(tidyverse, data.table, here,
       lubridate, sf, googledrive,
       openxlsx, abjutils, PNADcIBGE,
       survey)

options(scipen=999)

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|       PNADC uf e raça                |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

dadosPNADc <- get_pnadc(year=2020, quarter=4, vars=c("UF","V2010"))

totalracauf_2020.4 <- svytotal(x=~interaction(V2010, UF), design=dadosPNADc, na.rm=TRUE)
totalracauf_2020.4_df <- as.data.frame(ftable(x=totalracauf_2020.4))

setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(totalracauf_2020.4_df, "totalracauf_2020_4_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2020, quarter=1, vars=c("UF","V2010"))

totalracauf_2020.1 <- svytotal(x=~interaction(V2010, UF), design=dadosPNADc, na.rm=TRUE)
totalracauf_2020.1_df <- as.data.frame(ftable(x=totalracauf_2020.1))

setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(totalracauf_2020.1_df, "totalracauf_2020_1_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2020, quarter=2, vars=c("UF","V2010"))

totalracauf_2020.2 <- svytotal(x=~interaction(V2010, UF), design=dadosPNADc, na.rm=TRUE)
totalracauf_2020.2_df <- as.data.frame(ftable(x=totalracauf_2020.2))

setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(totalracauf_2020.2_df, "totalracauf_2020_2_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2020, quarter=3, vars=c("UF","V2010"))

totalracauf_2020.3 <- svytotal(x=~interaction(V2010, UF), design=dadosPNADc, na.rm=TRUE)
totalracauf_2020.3_df <- as.data.frame(ftable(x=totalracauf_2020.3))

setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(totalracauf_2020.3_df, "totalracauf_2020_3_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2021, quarter=1, vars=c("UF","V2010"))

totalracauf_2021.1 <- svytotal(x=~interaction(V2010, UF), design=dadosPNADc, na.rm=TRUE)
totalracauf_2021.1_df <- as.data.frame(ftable(x=totalracauf_2021.1))

setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(totalracauf_2021.1_df, "totalracauf_2021_1_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2021, quarter=2, vars=c("UF","V2010"))

totalracauf_2021.2 <- svytotal(x=~interaction(V2010, UF), design=dadosPNADc, na.rm=TRUE)
totalracauf_2021.2_df <- as.data.frame(ftable(x=totalracauf_2021.2))

setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(totalracauf_2021.2_df, "totalracauf_2021_2_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2021, quarter=3, vars=c("UF","V2010"))

totalracauf_2021.3 <- svytotal(x=~interaction(V2010, UF), design=dadosPNADc, na.rm=TRUE)
totalracauf_2021.3_df <- as.data.frame(ftable(x=totalracauf_2021.3))

setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(totalracauf_2021.3_df, "totalracauf_2021_3_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2021, quarter=4, vars=c("UF","V2010"))

totalracauf_2021.4 <- svytotal(x=~interaction(V2010, UF), design=dadosPNADc, na.rm=TRUE)
totalracauf_2021.4_df <- as.data.frame(ftable(x=totalracauf_2021.4))

setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(totalracauf_2021.4_df, "totalracauf_2021_4_df.xlsx")

# .--------------------------------------------.
# |############################################|
# |##.--------------------------------------.##|
# |##|       PNADC idade e raça             |##|
# |##°--------------------------------------°##|
# |############################################|
# '--------------------------------------------°

dadosPNADc <- get_pnadc(year=2020, quarter=1, vars=c("V2009","V2010"))
total_2020.1 <- svytotal(x=~interaction(V2010, V2009), design=dadosPNADc, na.rm=TRUE)
total_2020.1_df <- as.data.frame(ftable(x=total_2020.1))
setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(total_2020.1_df, "totalraca_idade_2020_1_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2020, quarter=2, vars=c("V2009","V2010"))
total_2020.2 <- svytotal(x=~interaction(V2010, V2009), design=dadosPNADc, na.rm=TRUE)
total_2020.2_df <- as.data.frame(ftable(x=total_2020.2))
setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(total_2020.2_df, "totalraca_idade_2020_2_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2020, quarter=3, vars=c("V2009","V2010"))
total_2020.3 <- svytotal(x=~interaction(V2010, V2009), design=dadosPNADc, na.rm=TRUE)
total_2020.3_df <- as.data.frame(ftable(x=total_2020.3))
setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(total_2020.3_df, "totalraca_idade_2020_3_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2020, quarter=4, vars=c("V2009","V2010"))
total_2020.4 <- svytotal(x=~interaction(V2010, V2009), design=dadosPNADc, na.rm=TRUE)
total_2020.4_df <- as.data.frame(ftable(x=total_2020.4))
setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(total_2020.4_df, "totalraca_idade_2020_4_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2021, quarter=1, vars=c("V2009","V2010"))
total_2021.1 <- svytotal(x=~interaction(V2010, V2009), design=dadosPNADc, na.rm=TRUE)
total_2021.1_df <- as.data.frame(ftable(x=total_2021.1))
setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(total_2021.1_df, "totalraca_idade_2021_1_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *
dadosPNADc <- get_pnadc(year=2021, quarter=2, vars=c("V2009","V2010"))
total_2021.2 <- svytotal(x=~interaction(V2010, V2009), design=dadosPNADc, na.rm=TRUE)
total_2021.2_df <- as.data.frame(ftable(x=total_2021.2))
setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(total_2021.2_df, "totalraca_idade_2021_2_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2021, quarter=3, vars=c("V2009","V2010"))
total_2021.3 <- svytotal(x=~interaction(V2010, V2009), design=dadosPNADc, na.rm=TRUE)
total_2021.3_df <- as.data.frame(ftable(x=total_2021.3))
setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(total_2021.3_df, "totalraca_idade_2021_3_df.xlsx")

#        |#|
#       \###/
#        \#/
#         *

dadosPNADc <- get_pnadc(year=2021, quarter=4, vars=c("V2009","V2010"))
total_2021.4 <- svytotal(x=~interaction(V2010, V2009), design=dadosPNADc, na.rm=TRUE)
total_2021.4_df <- as.data.frame(ftable(x=total_2021.4))
setwd("~/Documentos/projetos/afrodados/afrodados-analise-covid-sim-versao-2/outputs")
write.xlsx(total_2021.4_df, "totalraca_idade_2021_4_df.xlsx")

#                                      ~~~~~ Fim ~~~~~
