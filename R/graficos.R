# En graficos se usa el guion ASCII: el signo menos tipografico no existe en las
# fuentes de algunos dispositivos (p. ej. pdf).
.fmt_g <- function(x, d = 2) sub("\u2212", "-", fmt_es(x, d), fixed = TRUE)

.col_marca <- function(alerta) ifelse(alerta != "", "#c0392b", "#1f3a5f")

.dibuja_sector <- function(s, jones, nivel, etiquetas = TRUE, simulado = FALSE) {
  z <- s$datos
  a <- s$ajuste
  inf <- s$influencia
  xr <- range(z$som); yr <- range(c(z$esov, 0))
  xs <- seq(xr[1], xr[2], length.out = 60)
  pr <- stats::predict(a$modelo, data.frame(x = xs), interval = "confidence", level = nivel)
  yj <- jones[["alfa"]] + jones[["beta"]] * xs
  yl <- range(c(yr, pr, yj))
  graphics::plot(z$som, z$esov, type = "n", xlim = xr + c(-0.05, 0.12) * diff(xr), ylim = yl,
                 xlab = "SOM: cuota de mercado (%)",
                 ylab = "ESOV = SOV - SOM (puntos porcentuales)", main = s$sector)
  graphics::polygon(c(xs, rev(xs)), c(pr[, "lwr"], rev(pr[, "upr"])),
                    col = grDevices::adjustcolor("#1f3a5f", 0.15), border = NA)
  graphics::abline(h = 0, lty = 3, col = "grey40")
  graphics::lines(xs, yj, lty = 2, col = "#b9770e", lwd = 2)
  graphics::lines(xs, pr[, "fit"], col = "#1f3a5f", lwd = 2)
  graphics::points(z$som, z$esov, pch = 19, col = .col_marca(inf$alerta), cex = 1.2)
  if (etiquetas) {
    graphics::text(z$som, z$esov, z$marca, pos = 3, cex = 0.65, offset = 0.4,
                   col = .col_marca(inf$alerta))
  }
  graphics::legend("topright", bty = "n", cex = 0.75,
                   legend = c(paste0("MCO (beta = ", .fmt_g(a$beta), ")"),
                              paste0("Jones (beta = ", .fmt_g(jones[["beta"]]), ")"),
                              "Marca con alerta"),
                   lty = c(1, 2, NA), pch = c(NA, NA, 19), lwd = c(2, 2, NA),
                   col = c("#1f3a5f", "#b9770e", "#c0392b"))
  if (simulado) {
    graphics::mtext("DATOS SINTETICOS", side = 3, line = 0, adj = 0, col = "#c0392b",
                    cex = 0.7, font = 2)
  }
  invisible(NULL)
}

#' Gráfico de dispersión ESOV-SOM con recta, banda de confianza y referencia de Jones
#'
#' Dibuja, por categoría, el exceso de cuota de voz frente a la cuota de
#' mercado, con la recta de mínimos cuadrados y su banda de confianza para la
#' media, la recta de referencia de Jones (discontinua) y las marcas con alerta
#' de influencia en rojo. Los gráficos de datos simulados llevan la marca
#' «DATOS SINTETICOS».
#'
#' @param x Objeto `sov_analisis` o datos admitidos por [sov_analiza()].
#' @param categoria Identificador (`caso`) de una categoría; por defecto, todas.
#' @param etiquetas Si `TRUE`, rotula las marcas.
#' @return `NULL`, de forma invisible. Se llama por su efecto gráfico.
#' @examples
#' x <- sov_analiza(adage2019, B = 0)
#' sov_grafico(x, "auto_marcas")
#' @export
sov_grafico <- function(x, categoria = NULL, etiquetas = TRUE) {
  x <- sov_analiza(x, B = 0)
  ss <- Filter(function(s) !is.null(s$ajuste), x$sectores)
  if (!is.null(categoria)) {
    if (!all(categoria %in% names(ss))) {
      stop("Categor\u00eda no encontrada. Disponibles: ", paste(names(ss), collapse = ", "),
           call. = FALSE)
    }
    ss <- ss[categoria]
  }
  if (!length(ss)) stop("No hay categor\u00edas con al menos 4 marcas que dibujar.", call. = FALSE)
  k <- length(ss)
  if (k > 1L) {
    nc <- if (k <= 4L) 2L else 3L
    op <- graphics::par(mfrow = c(ceiling(k / nc), nc), mar = c(4, 4, 2.5, 1))
    on.exit(graphics::par(op), add = TRUE)
  }
  for (s in ss) .dibuja_sector(s, x$jones, x$nivel, etiquetas, isTRUE(x$simulado))
  invisible(NULL)
}

#' Mapa SOV-SOM: cada marca como un punto, con zonas de cosecha e inversión
#'
#' Dibuja la cuota de voz (SOV, eje horizontal) frente a la cuota de mercado
#' (SOM, eje vertical). La diagonal es el equilibrio SOV = SOM (ESOV = 0); por
#' encima está la zona de cosecha (la marca vende más de lo que habla) y por
#' debajo la zona de inversión (habla más de lo que vende). La línea roja
#' discontinua es la aproximación lineal a la curva de Jones (1990)
#' trasladada a este plano: ESOV = alfa + beta * SOM equivale a
#' SOV = alfa + (1 + beta) * SOM.
#'
#' @param x Objeto `sov_analisis` o datos admitidos por [sov_analiza()].
#' @param categoria Identificador de la categoría (por defecto, la primera con al menos 4 marcas).
#' @param marca Marca que se resalta en rojo (opcional).
#' @param jones Si `TRUE` (por defecto), dibuja la referencia de Jones. Sus valores
#'   son alfa = +6,4 y beta = -0,38.
#' @param valores Si `TRUE` (por defecto), añade el SOV y el SOM junto a cada marca.
#' @return `NULL`, de forma invisible.
#' @examples
#' sov_mapa(adage2019, "auto_marcas", marca = "Chevrolet")
#' @export
sov_mapa <- function(x, categoria = NULL, marca = NULL, jones = TRUE, valores = NULL) {
  x <- sov_analiza(x, B = 0)
  ss <- Filter(function(s) !is.null(s$ajuste), x$sectores)
  if (!length(ss)) stop("No hay categor\u00edas con al menos 4 marcas que dibujar.", call. = FALSE)
  if (is.null(categoria)) categoria <- names(ss)[1]
  if (length(categoria) != 1L || !categoria %in% names(ss))
    stop("Categor\u00eda no encontrada. Disponibles: ", paste(names(ss), collapse = ", "), call. = FALSE)
  z <- ss[[categoria]]$datos
  if (!is.null(marca) && !marca %in% z$marca)
    stop("Marca no encontrada. Disponibles: ", paste(z$marca, collapse = ", "), call. = FALSE)
  if (is.null(valores)) valores <- nrow(z) <= 6L
  .fig_mapa(z, marca, if (isTRUE(jones)) x$jones else NULL, isTRUE(valores))
}

#' Gráfico de bosque (forest plot) de las pendientes por categoría
#'
#' Representa la pendiente beta de cada categoría con su intervalo de confianza,
#' la referencia 0 (paridad SOV = SOM) y el valor de Jones. Permite ver de un
#' vistazo qué categorías son compatibles con la curva de Jones y cuáles no.
#'
#' @param x Objeto `sov_analisis` o datos admitidos por [sov_analiza()].
#' @return `NULL`, de forma invisible.
#' @examples
#' sov_grafico_bosque(sov_analiza(adage2019, B = 0))
#' @export
sov_grafico_bosque <- function(x) {
  x <- sov_analiza(x, B = 0)
  ss <- Filter(function(s) !is.null(s$ajuste), x$sectores)
  if (!length(ss)) stop("No hay categor\u00edas con al menos 4 marcas.", call. = FALSE)
  b <- vapply(ss, function(s) s$ajuste$beta, 0)
  lo <- vapply(ss, function(s) s$ajuste$ic_beta[1], 0)
  hi <- vapply(ss, function(s) s$ajuste$ic_beta[2], 0)
  nm <- vapply(ss, function(s) s$sector, "")
  o <- order(b)
  b <- b[o]; lo <- lo[o]; hi <- hi[o]; nm <- nm[o]
  k <- length(b)
  op <- graphics::par(mar = c(4, 11, 2.5, 1))
  on.exit(graphics::par(op), add = TRUE)
  graphics::plot(b, seq_len(k), xlim = range(c(lo, hi, 0, x$jones[["beta"]])), ylim = c(0.5, k + 0.5),
                 yaxt = "n", ylab = "", pch = 19, cex = 1.3, col = "#1f3a5f",
                 xlab = paste0("Pendiente beta de ESOV sobre SOM (IC ", x$nivel * 100, " %)"),
                 main = "Pendiente por categor\u00eda")
  graphics::segments(lo, seq_len(k), hi, seq_len(k), lwd = 2, col = "#1f3a5f")
  graphics::axis(2, at = seq_len(k), labels = nm, las = 1)
  graphics::abline(v = 0, lty = 3, col = "grey40")
  graphics::abline(v = x$jones[["beta"]], lty = 2, col = "#b9770e", lwd = 2)
  graphics::legend("bottomright", bty = "n", cex = 0.8, lty = c(3, 2), lwd = c(1, 2),
                   col = c("grey40", "#b9770e"),
                   legend = c("Paridad (beta = 0)", paste0("Jones (beta = ", .fmt_g(x$jones[["beta"]]), ")")))
  if (isTRUE(x$simulado)) {
    graphics::mtext("DATOS SINTETICOS", side = 3, line = 0, adj = 0, col = "#c0392b", cex = 0.7, font = 2)
  }
  invisible(NULL)
}

#' @export
plot.sov_analisis <- function(x, ...) {
  sov_grafico(x)
}
