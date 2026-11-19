#' mediaSOV: cuota de voz, cuota de mercado y simulación fundamentada
#'
#' Analiza la relación entre la cuota de voz (SOV) y la cuota de mercado (SOM)
#' de las marcas de una categoría y genera datos sintéticos cuyos supuestos
#' proceden de la literatura académica, con la procedencia de cada parámetro
#' declarada de forma explícita.
#'
#' @section Para empezar (sin saber R):
#' \enumerate{
#'   \item `sov_demo()` ejecuta el análisis completo con los datos de ejemplo.
#'   \item `sov_asistente()` abre una aplicación en el navegador.
#'   \item `sov_plantilla()` crea un CSV de muestra que se rellena con los
#'     datos propios; después, `sov_analiza("mis_datos_sov.csv")`.
#'   \item `sov_informe(x)` genera un informe HTML con ayudas interpretativas.
#' }
#'
#' @section Definiciones:
#' SOM es la cuota de mercado de la marca (%); SOV es su cuota de voz, esto es,
#' su gasto en medios dividido por el gasto total de la categoría (%); y
#' ESOV = SOV - SOM es el exceso de cuota de voz. El modelo estimado por sector
#' es ESOV = alfa + beta * SOM + error.
#'
#' @section Datos sintéticos:
#' `sov_simula()` y `sov_simula_dinamica()` generan datos con cierre exacto de
#' mercado (las cuotas suman 100). Los datos simulados **no** son evidencia
#' empírica: sirven para comprobar métodos, calcular potencia y enseñar. Todos
#' los objetos simulados llevan la marca `simulado = TRUE` y la ficha de sus
#' parámetros.
#'
#' @keywords internal
"_PACKAGE"

.onAttach <- function(libname, pkgname) {
  v <- tryCatch(as.character(utils::packageVersion(pkgname)), error = function(e) "")
  packageStartupMessage(
    "mediaSOV ", v, ": para empezar, escriba sov_demo() o sov_asistente()."
  )
}
