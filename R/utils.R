# Utilidades internas -----------------------------------------------------------
# Recta de mínimos cuadrados ajustada a los diez tramos de cuota de la tabla
# «Average Share of Voice Compared with Share of Market» (Jones, 1990, p. 40),
# tomados en su punto medio: ESOV = 6,4 - 0,38 * SOM.
.jones_slide <- c(alfa = 6.4, beta = -0.38)

`%||%` <- function(a, b) if (is.null(a)) b else a

# Número con coma decimal y signo menos tipográfico.
fmt_es <- function(x, d = 2, signo = FALSE) {
  x <- ifelse(!is.na(x) & round(x, d) == 0, 0, x)
  s <- ifelse(is.na(x), "\u2014",
              formatC(x, format = "f", digits = d, decimal.mark = ","))
  s <- sub("^-", "\u2212", s)
  if (signo) s <- ifelse(!is.na(x) & x > 0, paste0("+", s), s)
  s
}

# p-valor con formato de artículo.
fmt_p <- function(p) {
  ifelse(is.na(p), "\u2014",
         ifelse(p < 0.001, "< 0,001",
                formatC(p, format = "f", digits = 3, decimal.mark = ",")))
}

# Intervalo "[inf; sup]".
fmt_ic <- function(ic, d = 2) {
  paste0("[", fmt_es(ic[1], d), "; ", fmt_es(ic[2], d), "]")
}

# Escapa caracteres especiales de HTML.
.html_esc <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# Ejecuta `expr` con una semilla y restaura el estado del generador al terminar,
# de modo que las funciones del paquete no alteran la reproducibilidad del
# usuario.
.con_semilla <- function(semilla, expr) {
  if (is.null(semilla)) return(expr)
  hay <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  previo <- if (hay) get(".Random.seed", envir = globalenv(), inherits = FALSE) else NULL
  on.exit({
    if (is.null(previo)) {
      if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
        rm(".Random.seed", envir = globalenv())
      }
    } else {
      assign(".Random.seed", previo, envir = globalenv())
    }
  }, add = TRUE)
  set.seed(semilla)
  expr
}

# Etiquetas de sector de los casos de Ad Age (coinciden con las de la slide 22).
.etiquetas_adage <- c(
  auto_marcas  = "Automoci\u00f3n",
  restaurantes = "Restauraci\u00f3n",
  telefonia    = "Telefon\u00eda m\u00f3vil",
  tarjetas     = "Tarjetas de cr\u00e9dito",
  cerveza      = "Cerveza",
  bebidas      = "Bebidas"
)

# Conjunto de datos incluido; se accede a el sin depender de que el paquete
# este adjunto (library) para que mediaSOV::funcion() tambien funcione.
.adage <- function() getExportedValue("mediaSOV", "adage2019")
