# Genera data/adage2019.rda a partir del CSV incluido en inst/extdata.
# Ejecutar desde la raiz del paquete: source("data-raw/adage2019.R")
adage2019 <- utils::read.csv("inst/extdata/sov_som_casos_adage2019.csv",
                             encoding = "UTF-8", stringsAsFactors = FALSE)
stopifnot(nrow(adage2019) == 60L, ncol(adage2019) == 13L)
save(adage2019, file = "data/adage2019.rda", compress = "xz", version = 2)
