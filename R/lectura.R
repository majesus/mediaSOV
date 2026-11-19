#' Lee un archivo CSV de cuotas de voz y de mercado
#'
#' Lee un CSV sin que el usuario tenga que conocer su codificación ni su
#' separador. Detecta automáticamente UTF-8 (con o sin BOM), Windows-1252/Latin-1
#' y UTF-16 (el «texto Unicode» de Excel); el separador (coma, punto y coma o
#' tabulador) y el separador decimal (punto o coma). Si el archivo es un libro
#' de Excel (`.xlsx`), lo indica y explica cómo guardarlo como CSV.
#'
#' Acepta dos formatos de columnas:
#' \describe{
#'   \item{Formato sencillo (recomendado)}{Columnas `categoria`, `marca`, `som`
#'     (cuota de mercado, en %) y `sov` (cuota de voz, en %). Opcional: `resto`
#'     (1 si la fila es «resto del mercado», no una marca). Si en lugar de `sov`
#'     se aporta `gasto` y `total` (gasto total de la categoría), el SOV se
#'     calcula como gasto / total * 100.}
#'   \item{Formato Ad Age}{El de `adage2019` y de [sov_ejemplo()]: `case_id`,
#'     `brand`, `market_share_pct`, `media_musd`, `industry_media_total_musd`
#'     e `is_rest`.}
#' }
#' Los nombres de columna admiten variantes habituales en español e inglés
#' (por ejemplo `cuota_mercado`, `cuota_voz`, `market_share`, `share_of_voice`).
#' Use [sov_plantilla()] para crear un archivo de muestra.
#'
#' @param ruta Ruta del archivo CSV.
#' @return Un `data.frame` con las columnas tal como figuran en el archivo
#'   (sin estandarizar). Pase el resultado a [sov_prepara()] o directamente a
#'   [sov_analiza()].
#' @examples
#' d <- sov_lee(sov_ejemplo())
#' head(d[, c("brand", "market_share_pct", "media_musd")])
#' @export
sov_lee <- function(ruta) {
  txt <- .leer_texto(ruta)
  sep <- .detecta_sep(txt)
  lin <- strsplit(txt, "\n", fixed = TRUE)[[1]]
  lin <- lin[nzchar(trimws(lin))]
  dec <- if (sep == "," ) "." else if (any(grepl("[0-9],[0-9]", lin[-1]))) "," else "."
  d <- tryCatch(
    utils::read.table(text = paste(lin, collapse = "\n"), header = TRUE, sep = sep,
                      dec = dec, quote = "\"", stringsAsFactors = FALSE,
                      check.names = FALSE, strip.white = TRUE, comment.char = "",
                      na.strings = c("NA", "", "N/A", "n/a", "#N/A")),
    error = function(e) {
      stop("No se pudo leer el CSV (", conditionMessage(e), "). ",
           "Compruebe que todas las filas tienen el mismo n\u00famero de columnas.",
           call. = FALSE)
    })
  if (ncol(d) < 3L) {
    stop("El archivo tiene menos de 3 columnas; se esperaban al menos ",
         "categoria, marca, som y sov (o sus equivalentes).", call. = FALSE)
  }
  d
}

.leer_texto <- function(ruta) {
  if (!is.character(ruta) || length(ruta) != 1L || is.na(ruta) || !nzchar(ruta)) {
    stop("`ruta` debe ser el nombre de un archivo CSV, por ejemplo \"datos.csv\".",
         call. = FALSE)
  }
  if (!file.exists(ruta)) {
    stop("No se encuentra el archivo \"", ruta, "\". Compruebe el nombre y la ",
         "carpeta de trabajo (escriba getwd() para verla). Para probar el ",
         "paquete use sov_ejemplo().", call. = FALSE)
  }
  n <- file.info(ruta)$size
  if (is.na(n) || n == 0) {
    stop("El archivo \"", ruta, "\" est\u00e1 vac\u00edo.", call. = FALSE)
  }
  b <- readBin(ruta, "raw", n)
  if (length(b) >= 2L && identical(b[1:2], as.raw(c(0x50, 0x4b)))) {
    stop("El archivo parece un libro de Excel (.xlsx), no un CSV. En Excel: ",
         "Archivo > Guardar como > CSV UTF-8 (delimitado por comas).",
         call. = FALSE)
  }
  if (length(b) >= 2L && identical(b[1:2], as.raw(c(0xff, 0xfe)))) {
    txt <- iconv(list(b[-(1:2)]), "UTF-16LE", "UTF-8")
    txt <- txt[[1]]
    if (is.na(txt)) stop("No se pudo interpretar el archivo (UTF-16).", call. = FALSE)
  } else {
    if (length(b) >= 3L && identical(b[1:3], as.raw(c(0xef, 0xbb, 0xbf)))) b <- b[-(1:3)]
    b <- b[b != as.raw(0)]
    txt <- tryCatch(rawToChar(b), error = function(e) {
      stop("No se pudo interpretar el archivo como texto.", call. = FALSE)
    })
    if (validUTF8(txt)) {
      Encoding(txt) <- "UTF-8"
    } else {
      conv <- iconv(txt, "CP1252", "UTF-8")
      if (is.na(conv)) conv <- iconv(txt, "latin1", "UTF-8")
      if (is.na(conv)) stop("No se pudo determinar la codificaci\u00f3n del archivo.", call. = FALSE)
      txt <- conv
    }
  }
  gsub("\r\n|\r", "\n", txt)
}

.detecta_sep <- function(txt) {
  lin <- strsplit(txt, "\n", fixed = TRUE)[[1]]
  lin <- lin[nzchar(trimws(lin))]
  if (!length(lin)) stop("El archivo no contiene datos.", call. = FALSE)
  cab <- lin[1]
  seps <- c(",", ";", "\t")
  cuenta <- vapply(seps, function(s) {
    length(regmatches(cab, gregexpr(s, cab, fixed = TRUE))[[1]])
  }, integer(1))
  if (max(cuenta) == 0L) {
    stop("No se detecta el separador de columnas en la primera fila. ",
         "Use comas, punto y coma o tabuladores.", call. = FALSE)
  }
  seps[which.max(cuenta)]
}

.norm_nombre <- function(x) {
  x <- tolower(trimws(x))
  x <- chartr("\u00e1\u00e9\u00ed\u00f3\u00fa\u00fc\u00f1", "aeiouun", x)
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_+|_+$", "", x)
}

.alias_columnas <- list(
  caso   = c("caso", "case_id", "categoria", "sector", "mercado", "industria",
             "category", "market", "case"),
  marca  = c("marca", "brand", "anunciante", "empresa"),
  som    = c("som", "cuota_mercado", "cuota_de_mercado", "market_share",
             "market_share_pct", "share_of_market", "cuota_ventas"),
  sov    = c("sov", "cuota_voz", "cuota_de_voz", "share_of_voice",
             "cuota_publicitaria", "cuota_inversion"),
  gasto  = c("gasto", "inversion", "inversion_publicitaria", "spend",
             "media_musd", "gasto_medios", "ad_spend"),
  total  = c("total", "total_categoria", "total_sector", "gasto_total",
             "industry_media_total_musd", "total_gasto"),
  resto  = c("resto", "is_rest", "otros", "rest")
)

.a_numero <- function(x, nombre) {
  if (is.numeric(x)) return(as.numeric(x))
  y <- suppressWarnings(as.numeric(gsub(",", ".", gsub("%", "", as.character(x), fixed = TRUE),
                                        fixed = TRUE)))
  nuevos <- sum(is.na(y) & !is.na(x) & nzchar(trimws(as.character(x))))
  if (nuevos > 0) {
    warning("En la columna `", nombre, "` hay ", nuevos, " valor(es) que no son n\u00fameros; ",
            "se tratan como ausentes.", call. = FALSE)
  }
  y
}

#' Prepara los datos para el análisis
#'
#' Convierte el resultado de [sov_lee()], un `data.frame` propio o un objeto
#' simulado en la tabla estándar del paquete (clase `sov_datos`), con las
#' columnas `caso`, `sector`, `marca`, `som`, `sov`, `esov`, `resto` y
#' `simulado`. Comprueba la coherencia de los datos y avisa, en lenguaje claro,
#' de cualquier problema (cuotas fuera de \[0, 100\], marcas duplicadas, valores
#' ausentes, cuotas en proporción en lugar de en %, categorías con menos de
#' cuatro marcas).
#'
#' @param x Ruta de un CSV, `data.frame` (formato sencillo o Ad Age) u objeto
#'   `sov_datos`.
#' @param incluir_resto Si `FALSE` (por defecto), se excluyen las filas «resto
#'   del mercado», que no son marcas.
#' @return Un objeto de clase `sov_datos`.
#' @examples
#' d <- sov_prepara(adage2019)
#' d
#' @export
sov_prepara <- function(x, incluir_resto = FALSE) {
  if (inherits(x, "sov_datos")) {
    d <- x
    if (!incluir_resto) d <- d[!d$resto, , drop = FALSE]
    return(.reclasifica(d))
  }
  if (is.character(x) && length(x) == 1L) x <- sov_lee(x)
  if (!is.data.frame(x)) {
    stop("`x` debe ser la ruta de un CSV, un data.frame o un objeto `sov_datos`.",
         call. = FALSE)
  }
  nm <- .norm_nombre(names(x))
  col <- function(clave) {
    i <- match(.alias_columnas[[clave]], nm)
    i <- i[!is.na(i)]
    if (length(i)) i[1] else NA_integer_
  }
  adage <- all(c("case_id", "brand", "market_share_pct", "media_musd",
                 "industry_media_total_musd") %in% nm)
  if (adage) {
    g <- function(n) x[[match(n, nm)]]
    caso <- as.character(g("case_id"))
    som  <- .a_numero(g("market_share_pct"), "market_share_pct")
    gasto <- .a_numero(g("media_musd"), "media_musd")
    total <- .a_numero(g("industry_media_total_musd"), "industry_media_total_musd")
    sov  <- gasto / total * 100
    marca <- as.character(g("brand"))
    resto <- if ("is_rest" %in% nm) as.character(g("is_rest")) %in% c("1", "TRUE", "true", "T") else rep(FALSE, length(som))
    sector <- ifelse(caso %in% names(.etiquetas_adage), unname(.etiquetas_adage[caso]),
                     if ("case_title" %in% nm) sub("\\s*\u00b7.*$", "", as.character(g("case_title"))) else caso)
  } else {
    i_marca <- col("marca"); i_som <- col("som")
    i_sov <- col("sov"); i_gasto <- col("gasto"); i_total <- col("total")
    faltan <- c(if (is.na(i_marca)) "marca", if (is.na(i_som)) "som (cuota de mercado)",
                if (is.na(i_sov) && is.na(i_gasto)) "sov (cuota de voz) o gasto")
    if (length(faltan)) {
      stop("Faltan columnas: ", paste(faltan, collapse = "; "), ". ",
           "Columnas encontradas: ", paste(names(x), collapse = ", "), ". ",
           "Use sov_plantilla() para crear un archivo con el formato esperado.",
           call. = FALSE)
    }
    i_caso <- col("caso")
    caso <- if (is.na(i_caso)) rep("Mercado", nrow(x)) else as.character(x[[i_caso]])
    sector <- caso
    marca <- as.character(x[[i_marca]])
    som <- .a_numero(x[[i_som]], "som")
    if (!is.na(i_sov)) {
      sov <- .a_numero(x[[i_sov]], "sov")
    } else {
      gasto <- .a_numero(x[[i_gasto]], names(x)[i_gasto])
      if (!is.na(i_total)) {
        total <- .a_numero(x[[i_total]], names(x)[i_total])
      } else {
        total <- stats::ave(gasto, caso, FUN = function(v) sum(v, na.rm = TRUE))
        warning("No hay columna con el gasto total de la categor\u00eda: se calcula como la ",
                "suma de las filas de cada categor\u00eda (equivale a suponer que las filas ",
                "recogen todo el mercado).", call. = FALSE)
      }
      sov <- gasto / total * 100
    }
    i_resto <- col("resto")
    resto <- if (is.na(i_resto)) rep(FALSE, length(som)) else
      as.character(x[[i_resto]]) %in% c("1", "TRUE", "true", "T", "S\u00ed", "Si", "si", "s\u00ed")
  }
  if (length(som) && all(som[!is.na(som)] <= 1) && all(sov[!is.na(sov)] <= 1)) {
    warning("Las cuotas parecen estar en proporci\u00f3n (0-1) y no en %; se multiplican por 100.",
            call. = FALSE)
    som <- som * 100; sov <- sov * 100
  }
  d <- data.frame(caso = caso, sector = sector, marca = marca, som = som, sov = sov,
                  resto = resto, stringsAsFactors = FALSE)
  .valida_datos(d)
  d <- d[is.finite(d$som) & is.finite(d$sov), , drop = FALSE]
  d$esov <- d$sov - d$som
  d$simulado <- FALSE
  if (!incluir_resto) d <- d[!d$resto, , drop = FALSE]
  d <- d[, c("caso", "sector", "marca", "som", "sov", "esov", "resto", "simulado")]
  rownames(d) <- NULL
  d$caso <- factor(d$caso, levels = unique(d$caso))
  structure(d, class = c("sov_datos", "data.frame"))
}

.reclasifica <- function(d) {
  d <- as.data.frame(unclass(d), stringsAsFactors = FALSE)
  rownames(d) <- NULL
  d$caso <- factor(as.character(d$caso), levels = unique(as.character(d$caso)))
  structure(d, class = c("sov_datos", "data.frame"))
}

.valida_datos <- function(d) {
  nd <- d[!d$resto, , drop = FALSE]
  aus <- sum(!is.finite(d$som) | !is.finite(d$sov))
  if (aus > 0) {
    warning(aus, " fila(s) con cuota de mercado o de voz ausente o no num\u00e9rica ",
            "se excluyen del an\u00e1lisis.", call. = FALSE)
  }
  fuera <- sum(nd$som < 0 | nd$som > 100 | nd$sov < 0 | nd$sov > 100, na.rm = TRUE)
  if (fuera > 0) {
    warning(fuera, " fila(s) tienen una cuota fuera del intervalo [0, 100] %. ",
            "Revise las unidades.", call. = FALSE)
  }
  dup <- sum(duplicated(nd[, c("caso", "marca")]))
  if (dup > 0) {
    warning(dup, " marca(s) aparecen duplicadas dentro de una misma categor\u00eda.",
            call. = FALSE)
  }
  n <- table(nd$caso[is.finite(nd$som) & is.finite(nd$sov)])
  pocas <- names(n)[n < 4]
  if (length(pocas)) {
    warning("Las categor\u00edas con menos de 4 marcas no se pueden ajustar y se omitir\u00e1n: ",
            paste(pocas, collapse = ", "), ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' @export
print.sov_datos <- function(x, ...) {
  d <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  sim <- nrow(d) > 0 && any(d$simulado)
  cat("<sov_datos> ", nrow(d), " filas, ", length(unique(d$caso)), " categor\u00edas",
      if ("periodo" %in% names(d)) paste0(", ", length(unique(d$periodo)), " per\u00edodos") else "",
      if (sim) "  ** DATOS SINT\u00c9TICOS (no son evidencia emp\u00edrica) **" else "", "\n", sep = "")
  nd <- d[!d$resto, , drop = FALSE]
  if (nrow(nd) && !("periodo" %in% names(nd))) {
    nd$caso <- droplevels(factor(nd$caso))
    res <- do.call(rbind, lapply(split(nd, nd$caso), function(z) {
      data.frame(categoria = as.character(z$sector[1]), marcas = nrow(z),
                 SOM_cubierta = round(sum(z$som), 1), SOV_cubierta = round(sum(z$sov), 1),
                 stringsAsFactors = FALSE)
    }))
    rownames(res) <- NULL
    print(res, row.names = FALSE)
    cat("(SOM_cubierta y SOV_cubierta: suma de las marcas incluidas, en %)\n")
  } else if (nrow(nd)) {
    print(utils::head(nd, 6), row.names = FALSE)
    cat("... (panel en formato largo: una fila por marca y per\u00edodo)\n")
  }
  invisible(x)
}
