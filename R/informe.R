#' Informe reproducible en HTML
#'
#' Genera un informe HTML autocontenido con los resultados de un análisis:
#' tablas, gráficos, lectura en lenguaje llano, glosario, limitaciones y
#' referencias. Si los datos son sintéticos, el informe lo declara de forma
#' visible e incluye el postulado, los parámetros y su procedencia.
#'
#' @param datos Objeto `sov_analisis` o datos admitidos por [sov_analiza()].
#' @param archivo Ruta del HTML de salida (por defecto, `informe_sov.html` en
#'   el directorio de trabajo).
#' @param titulo Título del informe.
#' @param autor Autor (opcional).
#' @param abrir Si `TRUE`, abre el informe en el navegador.
#' @param B Remuestras del bootstrap si `datos` aún no está analizado.
#' @param guias Si `TRUE` (por defecto), incluye las dos guías paso a paso para
#'   estudiantes ([sov_guia()]), con las cifras de los datos analizados.
#' @param categoria,marca Categoría (identificador o nombre) y marca que sirven de
#'   ejemplo en las guías; por defecto, la primera categoría ajustable y su marca
#'   de mayor cuota.
#' @param epsilon,anios,inversion Elasticidad supuesta, horizonte en años y
#'   cambio de inversión (%) de la guía de la marca; véase [sov_guia()].
#' @return La ruta del archivo, de forma invisible.
#' @details Requiere los paquetes `rmarkdown` y `knitr` y Pandoc (incluido en
#'   RStudio). Si faltan, se indica cómo instalarlos.
#' @examples
#' \donttest{
#' if (requireNamespace("rmarkdown", quietly = TRUE) && rmarkdown::pandoc_available()) {
#'   sov_informe(adage2019, archivo = tempfile(fileext = ".html"), B = 200)
#' }
#' }
#' @export
sov_informe <- function(datos, archivo = "informe_sov.html",
                        titulo = "Cuota de voz y cuota de mercado: informe de an\u00e1lisis",
                        autor = "", abrir = interactive(), B = 1000, guias = TRUE,
                        categoria = NULL, marca = NULL, epsilon = 0.05, anios = 3, inversion = 50) {
  for (p in c("rmarkdown", "knitr")) {
    if (!requireNamespace(p, quietly = TRUE)) {
      stop("Falta el paquete '", p, "'. Inst\u00e1lelo con install.packages(\"", p, "\").", call. = FALSE)
    }
  }
  if (!rmarkdown::pandoc_available()) {
    stop("Falta Pandoc, necesario para generar el HTML. Viene con RStudio; ",
         "si no lo usa, v\u00e9ase https://pandoc.org/installing.html.", call. = FALSE)
  }
  x <- sov_analiza(datos, B = B)
  plantilla <- system.file("rmarkdown", "informe.Rmd", package = "mediaSOV")
  if (!nzchar(plantilla)) stop("No se encuentra la plantilla del informe.", call. = FALSE)
  archivo <- normalizePath(archivo, mustWork = FALSE)
  dir.create(dirname(archivo), showWarnings = FALSE, recursive = TRUE)
  tmp <- tempfile("informe_sov_"); dir.create(tmp)
  file.copy(plantilla, file.path(tmp, "informe.Rmd"))
  out <- rmarkdown::render(file.path(tmp, "informe.Rmd"), output_file = basename(archivo),
                           output_dir = dirname(archivo), quiet = TRUE,
                           params = list(x = x, titulo = titulo, autor = autor, guias = guias, categoria = categoria,
                                         marca = marca, epsilon = epsilon, anios = anios, inversion = inversion),
                           envir = new.env(parent = globalenv()))
  if (isTRUE(abrir)) utils::browseURL(out)
  message("Informe generado en: ", out)
  invisible(out)
}

#' Glosario de términos
#'
#' Define, en lenguaje llano y con precisión, los términos que usa el paquete.
#'
#' @param termino Texto opcional para filtrar (no distingue mayúsculas).
#' @return `data.frame` con las columnas `termino` y `definicion`.
#' @examples
#' sov_glosario()
#' sov_glosario("esov")
#' @export
sov_glosario <- function(termino = NULL) {
  g <- data.frame(
    termino = c("SOM (cuota de mercado)", "SOV (cuota de voz)", "ESOV (exceso de cuota de voz)",
                "beta (pendiente)", "Curva de Jones", "Intervalo de confianza (IC)", "Error est\u00e1ndar robusto (HC3)",
                "Theil-Sen", "Bootstrap de pares", "Palanca (leverage)", "Distancia de Cook / DFBETAS",
                "AICc y RMSE de validaci\u00f3n cruzada", "Elasticidad (gamma)", "Mercado cerrado",
                "Datos sint\u00e9ticos", "Postulado", "Estudio de recuperaci\u00f3n", "Cobertura"),
    definicion = c(
      "Porcentaje de las ventas (o cuota) de la categor\u00eda que corresponde a una marca.",
      "Porcentaje de la inversi\u00f3n publicitaria de la categor\u00eda que realiza una marca.",
      "SOV menos SOM, en puntos porcentuales. Positivo: la marca invierte m\u00e1s de lo que le corresponde por su cuota.",
      "Cambio medio del ESOV por cada punto porcentual adicional de SOM. Negativo: las marcas grandes invierten proporcionalmente menos.",
      "Regularidad emp\u00edrica (Jones, 1990) seg\u00fan la cual la intensidad publicitaria decrece con la cuota de mercado.",
      "Rango de valores del par\u00e1metro compatible con los datos al nivel indicado; si contiene 0, el efecto no es distinguible de 0.",
      "Error est\u00e1ndar que no exige varianza constante del error (Long y Ervin, 2000); en cuotas, la dispersi\u00f3n suele crecer con la cuota.",
      "Pendiente mediana de todas las pendientes entre pares de marcas; poco sensible a valores extremos.",
      "Remuestreo de marcas con reemplazo para obtener un intervalo sin suponer normalidad.",
      "Medida de cu\u00e1n inusual es la cuota de una marca; las de palanca alta pueden dominar la recta.",
      "Medidas de cu\u00e1nto cambia la pendiente si se omite una marca.",
      "Criterios para comparar formas funcionales penalizando la complejidad (AICc) o evaluando la predicci\u00f3n fuera de muestra (RMSE).",
      "Exponente de SOV = c \u00b7 SOM^gamma. gamma < 1: econom\u00edas de escala; gamma = 1: proporcionalidad.",
      "Las cuotas de todas las marcas (incluido el \u00abresto\u00bb) suman 100 %. Si se incluye el resto, la recta se fuerza mec\u00e1nicamente.",
      "Datos generados por un modelo con par\u00e1metros conocidos. Sirven para comprobar m\u00e9todos, no para afirmar nada sobre el mundo real.",
      "Supuesto te\u00f3rico sobre c\u00f3mo se relacionan SOV y SOM (por ejemplo, la curva lineal de Jones o la paridad).",
      "Simulaci\u00f3n repetida de datos con verdad conocida para medir sesgo, error y cobertura de un m\u00e9todo.",
      "Proporci\u00f3n de intervalos que contienen el valor verdadero; deber\u00eda aproximarse al nivel nominal (95 %)."),
    stringsAsFactors = FALSE)
  if (!is.null(termino)) g <- g[grepl(termino, g$termino, ignore.case = TRUE) |
                                  grepl(termino, g$definicion, ignore.case = TRUE), , drop = FALSE]
  rownames(g) <- NULL
  g
}

#' Demostración guiada
#'
#' Recorre, con mensajes explicativos, un análisis completo: lectura de los
#' datos de ejemplo, ajuste, interpretación y gráfico; después simula datos
#' sintéticos con verdad conocida y comprueba que el método la recupera.
#'
#' @param grafico Si `TRUE` (por defecto en sesiones interactivas), dibuja los
#'   gráficos.
#' @return Lista invisible con `real`, `sintetico` y `verdad`.
#' @examples
#' sov_demo(grafico = FALSE)
#' @export
sov_demo <- function(grafico = interactive()) {
  say <- function(...) message(paste0(...))
  say("== 1. Datos reales de ejemplo (Ad Age, 2019): 6 categor\u00edas ==")
  real <- sov_analiza(adage2019, B = 300)
  print(sov_tabla(real, "resultados")[, c(1, 3, 4, 5)], row.names = FALSE)
  say("\n== 2. Lectura en lenguaje llano ==")
  cat(sov_interpreta(real)[1:2], sep = "\n\n")
  if (isTRUE(grafico)) sov_grafico(real, real$sectores[[1]]$caso)
  say("\n\n== 3. Datos sint\u00e9ticos con verdad conocida (postulado: curva de Jones) ==")
  sim <- sov_simula("jones_lineal", semilla = 2019)
  print(sim)
  sx <- sov_analiza(sim, B = 300)
  verdad <- attr(sim, "simulacion")$verdad
  est <- vapply(sx$sectores, function(s) if (is.null(s$ajuste)) NA_real_ else s$ajuste$beta, numeric(1))
  cmp <- data.frame(categoria = verdad$caso, beta_verdadera = round(verdad$beta_lineal_publicadas, 2),
                    beta_estimada = round(unname(est[as.character(verdad$caso)]), 2))
  say("\nPendiente verdadera (conocida) frente a la estimada:")
  print(cmp, row.names = FALSE)
  say("\nUna sola r\u00e9plica es ruidosa. El estudio de recuperaci\u00f3n repite la simulaci\u00f3n: ",
      "use sov_valida_simulacion(\"jones_lineal\", R = 200).")
  say("Para analizar sus datos: sov_plantilla() crea un archivo de muestra; sov_asistente() abre la aplicaci\u00f3n.")
  invisible(list(real = real, sintetico = sx, verdad = cmp))
}

#' Asistente interactivo (aplicación Shiny)
#'
#' Abre una aplicación en el navegador que permite cargar un CSV, usar los
#' datos de ejemplo o generar datos sintéticos, ver resultados y descargar el
#' informe. No requiere escribir código.
#'
#' @param ... Argumentos de [shiny::runApp()], por ejemplo `port`.
#' @return No retorna mientras la aplicación esté abierta.
#' @examples
#' \dontrun{
#' sov_asistente()
#' }
#' @export
sov_asistente <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Falta el paquete 'shiny'. Inst\u00e1lelo con install.packages(\"shiny\").", call. = FALSE)
  }
  dir <- system.file("shiny", "asistente", package = "mediaSOV")
  if (!nzchar(dir)) stop("No se encuentra la aplicaci\u00f3n.", call. = FALSE)
  shiny::runApp(dir, ...)
}
