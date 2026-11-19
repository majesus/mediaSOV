#' Casos de cuota de voz y de mercado (Ad Age, Marketing Fact Pack 2019)
#'
#' Seis categorías de mercado de Estados Unidos (2017) con la cuota de mercado
#' publicada de las marcas líderes y su gasto en medios medidos (Kantar Media).
#' Es el conjunto de datos de la slide 22 del material docente del autor.
#'
#' La fila «Resto del mercado» (`is_rest = 1`) es **derivada**: su cuota es
#' 100 menos la de las marcas publicadas y su gasto es el total de la industria
#' menos el de las marcas publicadas. Cierra los totales a 100 % pero no es una
#' marca. Las cifras están redondeadas en la fuente; las sumas pueden diferir de
#' los totales publicados en +-0,1 puntos o +-3 M$. «Medios medidos» no equivale
#' a inversión publicitaria total.
#'
#' @format Un `data.frame` de 60 filas y 13 columnas:
#' \describe{
#'   \item{case_id, case_title, sector}{Identificador, título y sector del caso.}
#'   \item{pdf_page}{Página del PDF de origen.}
#'   \item{share_basis}{Base de la cuota de mercado (unidades, ventas, etc.).}
#'   \item{industry_media_total_musd}{Gasto en medios medidos de toda la
#'     industria (millones de dólares).}
#'   \item{brand, owner}{Marca y propietario.}
#'   \item{market_share_pct}{Cuota de mercado publicada (SOM), en %.}
#'   \item{media_musd}{Gasto en medios medidos de la marca (millones de
#'     dólares); SOV = media_musd / industry_media_total_musd * 100.}
#'   \item{is_rest}{1 si la fila es el resto derivado del mercado.}
#'   \item{focal}{1 si es la marca por defecto de la calculadora de la slide.}
#'   \item{note}{Nota sobre la fila.}
#' }
#' @source Ad Age (2018-12-17), «Ad Age U.S. market leaders by category», en
#'   *Ad Age Marketing Fact Pack 2019*, páginas 10, 12 y 13 del PDF.
#'   Datos de 2017. Se reproducen aquí cifras publicadas con fines docentes y
#'   de investigación; se recomienda consultar la fuente original.
#' @examples
#' head(adage2019)
#' sov_prepara(adage2019)
"adage2019"

#' Ruta del CSV de ejemplo incluido en el paquete
#'
#' @return La ruta completa del archivo `sov_som_casos_adage2019.csv`.
#' @examples
#' sov_ejemplo()
#' @export
sov_ejemplo <- function() {
  system.file("extdata", "sov_som_casos_adage2019.csv", package = "mediaSOV",
              mustWork = TRUE)
}

#' Crea un CSV de muestra para rellenar con los datos propios
#'
#' Escribe un archivo con el formato esperado por [sov_analiza()]: una fila por
#' marca, con `categoria`, `marca`, `som` (cuota de mercado, %) y `sov` (cuota de
#' voz, %). Los números son **ficticios** y deben sustituirse. El archivo se
#' guarda en UTF-8 con BOM, con punto y coma como separador y coma decimal en
#' el formato `"excel"` (se abre correctamente con doble clic en Excel en
#' configuración regional española), o con coma y punto decimal en el formato
#' `"internacional"`.
#'
#' @param archivo Nombre del archivo que se creará.
#' @param formato `"excel"` (por defecto) o `"internacional"`.
#' @return La ruta del archivo, de forma invisible.
#' @examples
#' f <- tempfile(fileext = ".csv")
#' sov_plantilla(f)
#' sov_analiza(f, B = 0)
#' @export
sov_plantilla <- function(archivo = "mis_datos_sov.csv", formato = c("excel", "internacional")) {
  formato <- match.arg(formato)
  d <- data.frame(
    categoria = rep("Categor\u00eda ficticia", 6),
    marca = paste("Marca", LETTERS[1:6]),
    som = c(30, 22, 15, 12, 8, 5),
    sov = c(26, 24, 18, 10, 9, 6),
    stringsAsFactors = FALSE
  )
  num <- function(v) if (formato == "excel") sub(".", ",", format(v), fixed = TRUE) else format(v)
  sep <- if (formato == "excel") ";" else ","
  lin <- c(paste(names(d), collapse = sep),
           apply(cbind(d$categoria, d$marca, trimws(num(d$som)), trimws(num(d$sov))), 1,
                 paste, collapse = sep))
  con <- file(archivo, "wb")
  on.exit(close(con), add = TRUE)
  writeBin(as.raw(c(0xef, 0xbb, 0xbf)), con)
  writeBin(charToRaw(enc2utf8(paste0(paste(lin, collapse = "\r\n"), "\r\n"))), con)
  message("Archivo creado: ", normalizePath(archivo, mustWork = FALSE),
          "\nSustituya las cifras ficticias por las suyas (conserve los nombres de columna).")
  invisible(archivo)
}
