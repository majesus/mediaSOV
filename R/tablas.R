#' Tablas editadas de un análisis
#'
#' Devuelve tablas ya formateadas (coma decimal, signo menos tipográfico,
#' columnas rotuladas en español) listas para leer en consola, copiar a un
#' documento o incrustar en HTML. Cada tabla lleva en el atributo `nota` una
#' explicación de cómo leerla.
#'
#' @param x Objeto `sov_analisis` (o datos admitidos por [sov_analiza()]).
#' @param tipo Tabla pedida:
#' \describe{
#'   \item{`"resultados"`}{una fila por categoría: pendiente, intervalo, p, R²,
#'     Theil-Sen, rango al omitir marcas, umbral y lectura.}
#'   \item{`"influencia"`}{una fila por marca con palanca, t*, Cook, DFBETAS y
#'     alertas.}
#'   \item{`"formas"`}{comparación lineal / ln SOM / cuadrática.}
#'   \item{`"bootstrap"`}{intervalos bootstrap de la pendiente.}
#'   \item{`"elasticidad"`}{elasticidad SOV-SOM en escala logarítmica.}
#'   \item{`"cobertura"`}{marcas y cuotas cubiertas por categoría.}
#' }
#' @param categoria Opcional: identificador (`caso`) de una categoría para las
#'   tablas por marca o por forma.
#' @param formato `"data.frame"` (por defecto) o `"html"` (cadena HTML
#'   autocontenida, con estilos incrustados).
#' @return Un `data.frame` de caracteres con el atributo `nota`, o una cadena
#'   HTML.
#' @examples
#' x <- sov_analiza(adage2019, B = 0)
#' sov_tabla(x, "resultados")
#' sov_tabla(x, "influencia", categoria = "restaurantes")
#' @export
sov_tabla <- function(x, tipo = c("resultados", "influencia", "formas", "bootstrap",
                                  "elasticidad", "cobertura"),
                      categoria = NULL, formato = c("data.frame", "html")) {
  tipo <- match.arg(tipo)
  formato <- match.arg(formato)
  x <- sov_analiza(x, B = 0)
  ss <- x$sectores
  if (!is.null(categoria)) {
    if (!all(categoria %in% names(ss))) {
      stop("Categor\u00eda no encontrada. Disponibles: ", paste(names(ss), collapse = ", "),
           call. = FALSE)
    }
    ss <- ss[categoria]
  }
  niv <- fmt_es(x$nivel * 100, 0)
  res <- NULL; nota <- ""; resaltar <- NULL; titulo <- ""
  if (tipo == "resultados") {
    titulo <- "Pendiente de ESOV sobre SOM por categor\u00eda"
    res <- do.call(rbind, lapply(ss, function(s) {
      if (is.null(s$ajuste)) {
        return(data.frame(Categoria = s$sector, n = as.character(s$n), Beta = "\u2014",
                          IC = "\u2014", IC_HC3 = "\u2014", p = "\u2014", R2 = "\u2014", Theil_Sen = "\u2014",
                          Rango_sin_una_marca = "\u2014", Umbral_SOM = "\u2014",
                          Lectura = "Menos de 4 marcas: no se ajusta",
                          stringsAsFactors = FALSE))
      }
      a <- s$ajuste
      lect <- if (!(a$ic_beta[1] > 0 || a$ic_beta[2] < 0)) "No distinguible de 0"
              else if (a$beta < 0) "Econom\u00eda de escala" else "Deseconom\u00eda de escala"
      data.frame(Categoria = s$sector, n = as.character(a$n), Beta = fmt_es(a$beta),
                 IC = fmt_ic(a$ic_beta), IC_HC3 = fmt_ic(a$ic_beta_hc3), p = fmt_p(a$p_beta), R2 = fmt_es(a$r2),
                 Theil_Sen = fmt_es(a$ts_beta),
                 Rango_sin_una_marca = fmt_ic(a$loo_rango),
                 Umbral_SOM = if (is.na(a$som_umbral)) "\u2014" else paste0(fmt_es(a$som_umbral, 1), " %"),
                 Lectura = lect, stringsAsFactors = FALSE)
    }))
    names(res) <- c("Categor\u00eda", "n", "\u03b2", paste0("IC ", niv, " % de \u03b2"),
                    paste0("IC ", niv, " % robusto (HC3)"), "p",
                    "R\u00b2", "\u03b2 Theil-Sen", "\u03b2 al omitir cada marca", "Umbral SOM",
                    "Lectura")
    nota <- paste0("\u03b2 es la pendiente de ESOV = SOV \u2212 SOM sobre SOM (puntos porcentuales por punto de cuota). ",
                   "\u03b2 < 0: las marcas grandes invierten proporcionalmente menos (curva de Jones); \u03b2 = 0: SOV \u2248 SOM + constante. ",
                   "El intervalo robusto HC3 no supone varianza constante del error; con pocas marcas (n < 12) tiende a ser ligeramente optimista y el cl\u00e1sico, estrecho. El rango \u00abal omitir cada marca\u00bb mide la dependencia de una marca concreta; el umbral es la cuota en la que el ESOV medio se anula.")
  } else if (tipo == "influencia") {
    titulo <- "Diagn\u00f3stico de influencia por marca"
    res <- do.call(rbind, lapply(ss, function(s) {
      if (is.null(s$ajuste)) return(NULL)
      i <- s$influencia
      data.frame(Categoria = s$sector, Marca = i$marca, SOM = fmt_es(i$som, 1), SOV = fmt_es(i$sov, 1),
                 ESOV = fmt_es(i$esov, 1, signo = TRUE), Palanca = fmt_es(i$palanca),
                 t = fmt_es(i$t_stud), Cook = fmt_es(i$cook), DFBETAS = fmt_es(i$dfbetas),
                 beta_sin = fmt_es(i$beta_sin), Alerta = ifelse(i$alerta == "", "\u2014", i$alerta),
                 stringsAsFactors = FALSE)
    }))
    names(res) <- c("Categor\u00eda", "Marca", "SOM (%)", "SOV (%)", "ESOV (pp)", "Palanca", "t*",
                    "Cook", "DFBETAS", "\u03b2 sin la marca", "Alerta")
    nota <- paste0("Alertas: P = palanca > 4/n (cuota inusual); A = |t*| > 2 (ESOV at\u00edpico); ",
                   "I = Cook > 4/n o |DFBETAS| > 2/\u221an (la marca mueve la pendiente). ",
                   "Son umbrales heur\u00edsticos; la columna \u00ab\u03b2 sin la marca\u00bb muestra cu\u00e1nto cambia la pendiente al omitirla.")
    resaltar <- res[["Alerta"]] != "\u2014"
  } else if (tipo == "formas") {
    titulo <- "Comparaci\u00f3n de formas funcionales"
    res <- do.call(rbind, lapply(ss, function(s) {
      if (is.null(s$ajuste)) return(NULL)
      f <- s$formas
      data.frame(Categoria = s$sector, Forma = f$forma, RMSE = fmt_es(f$rmse_cv),
                 dAICc = fmt_es(f$delta_aicc, 1, signo = TRUE),
                 Mejor = ifelse(f$mejor_rmse & f$mejor_aicc, "RMSE y AICc",
                          ifelse(f$mejor_rmse, "RMSE", ifelse(f$mejor_aicc, "AICc", "\u2014"))),
                 stringsAsFactors = FALSE)
    }))
    names(res) <- c("Categor\u00eda", "Forma", "RMSE (validaci\u00f3n cruzada)", "\u0394AICc vs. lineal", "Mejor en")
    nota <- paste0("RMSE por validaci\u00f3n cruzada \u00abdejando una fuera\u00bb (puntos porcentuales de ESOV); \u0394AICc respecto a la recta ",
                   "(negativo = mejor que la recta; diferencias menores de 2 son indistinguibles). ",
                   "Con 6 a 10 marcas, la cuadr\u00e1tica sobreajusta con facilidad: v\u00e9ase el RMSE antes de aceptar una curva.")
    resaltar <- res[["Mejor en"]] != "\u2014"
  } else if (tipo == "bootstrap") {
    titulo <- "Bootstrap de pares de la pendiente"
    res <- do.call(rbind, lapply(ss, function(s) {
      b <- s$bootstrap
      if (is.null(b)) return(NULL)
      data.frame(Categoria = s$sector, MCO = fmt_ic(b$ols), TS = fmt_ic(b$ts),
                 P = paste0(fmt_es(b$p_neg * 100, 0), " %"), stringsAsFactors = FALSE)
    }))
    if (is.null(res)) {
      stop("El an\u00e1lisis se calcul\u00f3 con B = 0; vuelva a ejecutar sov_analiza() con B > 0.",
           call. = FALSE)
    }
    names(res) <- c("Categor\u00eda", paste0("IC ", niv, " % bootstrap (MCO)"),
                    paste0("IC ", niv, " % bootstrap (Theil-Sen)"), "Remuestras con \u03b2 < 0")
    nota <- "Intervalos percentil por remuestreo de marcas. Con pocas marcas son orientativos: un intervalo que cruza 0 no permite afirmar el signo."
  } else if (tipo == "elasticidad") {
    titulo <- "Elasticidad de SOV respecto a SOM (escala logar\u00edtmica)"
    res <- do.call(rbind, lapply(ss, function(s) {
      e <- s$elasticidad
      if (is.null(e)) return(NULL)
      data.frame(Categoria = s$sector, n = as.character(e$n), gamma = fmt_es(e$gamma),
                 IC = fmt_ic(e$ic), p = fmt_p(e$p_igual1),
                 Lectura = if (e$p_igual1 >= 0.05) "No distinguible de 1 (paridad)"
                           else if (e$gamma < 1) "Econom\u00eda de escala" else "Deseconom\u00eda de escala",
                 stringsAsFactors = FALSE)
    }))
    names(res) <- c("Categor\u00eda", "n", "\u03b3", paste0("IC ", niv, " % de \u03b3"), "p (\u03b3 = 1)", "Lectura")
    nota <- "\u03b3 es el exponente de SOV = c \u00b7 SOM^\u03b3. \u03b3 < 1: el gasto crece menos que proporcionalmente con la cuota."
  } else {
    titulo <- "Cobertura de los datos"
    res <- do.call(rbind, lapply(ss, function(s) {
      z <- s$datos
      data.frame(Categoria = s$sector, Marcas = as.character(nrow(z)),
                 SOM = paste0(fmt_es(sum(z$som), 1), " %"), SOV = paste0(fmt_es(sum(z$sov), 1), " %"),
                 stringsAsFactors = FALSE)
    }))
    names(res) <- c("Categor\u00eda", "Marcas", "SOM cubierta", "SOV cubierta")
    nota <- paste0("Suma de las cuotas de las marcas incluidas. Una cobertura baja significa que el an\u00e1lisis solo ve ",
                   "la parte alta del mercado, de modo que el intercepto es una extrapolaci\u00f3n.")
  }
  rownames(res) <- NULL
  attr(res, "nota") <- nota
  attr(res, "titulo") <- titulo
  attr(res, "resaltar") <- resaltar
  if (formato == "html") return(.tabla_html(res))
  res
}

# Convierte una tabla de sov_tabla() en HTML autocontenido.
.tabla_html <- function(res) {
  esc <- .html_esc
  cab <- paste0("<th>", esc(names(res)), "</th>", collapse = "")
  res_alerta <- attr(res, "resaltar")
  filas <- vapply(seq_len(nrow(res)), function(i) {
    cl <- if (!is.null(res_alerta) && isTRUE(res_alerta[i])) " class=\"alerta\"" else ""
    celdas <- paste0("<td>", esc(unlist(res[i, ], use.names = FALSE)), "</td>", collapse = "")
    paste0("<tr", cl, ">", celdas, "</tr>")
  }, character(1))
  estilo <- paste0(
    "<style>.sovtab{border-collapse:collapse;font-family:system-ui,Segoe UI,Arial,sans-serif;font-size:.9em;margin:1em 0}",
    ".sovtab caption{font-weight:700;text-align:left;padding:.3em 0}",
    ".sovtab th{background:#1f3a5f;color:#fff;padding:.45em .7em;text-align:center}",
    ".sovtab td{padding:.35em .7em;border-bottom:1px solid #d7dbe0;text-align:center}",
    ".sovtab td:first-child{text-align:left}.sovtab tr:nth-child(even){background:#f5f7fa}",
    ".sovtab tr.alerta{background:#fde8e8!important;font-weight:600}",
    ".sovnota{font-family:system-ui,Segoe UI,Arial,sans-serif;font-size:.8em;color:#4a5568;max-width:60em}</style>")
  paste0(estilo, "<table class=\"sovtab\"><caption>", esc(attr(res, "titulo")), "</caption><thead><tr>", cab,
         "</tr></thead><tbody>", paste(filas, collapse = ""), "</tbody></table>",
         "<p class=\"sovnota\"><em>C\u00f3mo leer esta tabla.</em> ", esc(attr(res, "nota")), "</p>")
}
