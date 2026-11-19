# Guias paso a paso (HTML). Estructura y tono inspirados en las dos guias para
# estudiantes de la slide 22: una pregunta unica por guia, pasos encadenados,
# preguntas retoricas, resultado destacado y cautelas explicitas. Todas las
# cifras se calculan con los datos analizados; los textos condicionales
# (p. ej., "cambia de signo") solo se emiten cuando los datos los respaldan.

.g_css <- function() {
  paste0('<style>',
  '.sg-root{font-size:16px;line-height:1.65;max-width:920px;color:#1a1a1a}',
  '.sg-root h3,.sg-root h4{line-height:1.3}',
  '.sg-intro{font-size:1.18em;font-weight:600}',
  '.sg-s{border:1px solid #cfcfcf;border-left:6px solid #1a1a1a;border-radius:6px;padding:14px 21px 16px;margin:26px 0;background:#fff;page-break-inside:avoid}',
  '.sg-step{font-size:12px;letter-spacing:.09em;text-transform:uppercase;color:#a0001c;font-weight:700}',
  '.sg-h{margin:4px 0 10px;font-size:20px}',
  '.sg-q{background:#f1f1f1;border-radius:4px;padding:9px 14px;font-weight:700;margin:18px 0 6px}',
  '.sg-res{background:#161616;color:#fff;border-radius:4px;padding:11px 16px;margin-top:18px}',
  '.sg-warn{border-left:5px solid #9a5b00;background:#fff4e0;padding:10px 16px;margin:16px 0}',
  '.sg-sim{border:3px solid #b00020;background:#fdecea;padding:11px 16px;margin:16px 0}',
  '.sg-note{font-size:.93em;color:#3d3d3d}',
  '.sg-eq{font-family:Consolas,"Courier New",monospace;background:#f6f6f6;border-radius:4px;padding:8px 13px;margin:11px 0;overflow-x:auto}',
  '.sg-fig{margin:16px 0;text-align:center}.sg-fig img{max-width:100%;height:auto;border:1px solid #e3e3e3}',
  '.sg-cap{font-size:.9em;color:#3d3d3d;margin-top:5px}',
  '.sg-root table.sg-tbl{border-collapse:collapse;margin:13px 0;font-size:.93em;width:auto}',
  '.sg-tbl th,.sg-tbl td{border:1px solid #cfcfcf;padding:5px 10px;text-align:left}',
  '.sg-tbl th{background:#ececec}.sg-tbl tr.hl td{background:#fdecea;font-weight:600}',
  '.sg-root code{background:#f3f3f3;padding:0 4px;border-radius:3px}',
  '.sg-root pre{background:#f6f6f6;border-radius:4px;padding:10px 14px;overflow-x:auto}',
  '</style>')
}

.g_p <- function(...) paste0("<p>", ..., "</p>")
.g_ul <- function(it) paste0("<ul>", paste0("<li>", it, "</li>", collapse = ""), "</ul>")
.g_ol <- function(it) paste0("<ol>", paste0("<li>", it, "</li>", collapse = ""), "</ol>")
.g_eq <- function(t) paste0('<div class="sg-eq">', t, "</div>")
.g_q <- function(q, a) paste0('<div class="sg-q">', q, "</div>", a)
.g_res <- function(t) paste0('<div class="sg-res">', t, "</div>")
.g_warn <- function(t) paste0('<div class="sg-warn">', t, "</div>")
.g_note <- function(t) paste0('<p class="sg-note">', t, "</p>")
.g_step <- function(i, n, titulo, cuerpo) {
  paste0('<section class="sg-s"><div class="sg-step">Paso ', i, " de ", n, "</div>",
         '<h4 class="sg-h">', titulo, "</h4>", paste(cuerpo, collapse = "\n"), "</section>")
}
.g_tbl <- function(df, hl = NULL) {
  th <- paste0("<th>", .html_esc(names(df)), "</th>", collapse = "")
  fila <- function(i) {
    cl <- if (!is.null(hl) && isTRUE(hl[i])) ' class="hl"' else ""
    paste0("<tr", cl, ">", paste0("<td>", .html_esc(as.character(unlist(df[i, ]))), "</td>", collapse = ""), "</tr>")
  }
  paste0('<table class="sg-tbl"><thead><tr>', th, "</tr></thead><tbody>",
         paste0(vapply(seq_len(nrow(df)), fila, ""), collapse = ""), "</tbody></table>")
}
.renombra <- function(d, nm) { names(d) <- nm; d }
.lista_es <- function(v) {
  v <- as.character(v)
  if (length(v) <= 1) return(v)
  paste0(paste(v[-length(v)], collapse = ", "), " y ", v[length(v)])
}
.pp <- function(v, d = 1) paste0(fmt_es(v, d, signo = TRUE), " pp")
.pc <- function(v, d = 1) paste0(fmt_es(v, d), " %")

.png_uri <- function(fun, alt, cap, w = 7, h = 4.4) {
  nota <- function(m) paste0('<p class="sg-note">[', m, "] ", cap, "</p>")
  if (!requireNamespace("knitr", quietly = TRUE)) {
    return(nota("Figura no disponible: instale el paquete knitr"))
  }
  f <- tempfile(fileext = ".png"); on.exit(unlink(f), add = TRUE)
  abierto <- tryCatch({
    grDevices::png(f, width = w, height = h, units = "in", res = 110)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!abierto) return(nota("Figura no disponible en este sistema"))
  ok <- tryCatch({ fun(); TRUE }, error = function(e) FALSE)
  grDevices::dev.off()
  if (!ok || !file.exists(f)) return(nota("Figura no disponible"))
  paste0('<figure class="sg-fig"><img alt="', .html_esc(alt), '" src="', knitr::image_uri(f),
         '"/><figcaption class="sg-cap">', cap, "</figcaption></figure>")
}

# ------------------------------------------------------------ figuras base
.COL_ROJO <- "#C8102E"


.etiquetas <- function(x, y, lab, resalta = NULL, cex = 0.8) {
  usr <- graphics::par("usr"); n <- length(x)
  w <- graphics::strwidth(lab, cex = cex); h <- graphics::strheight(lab, cex = cex) * 1.1
  dx <- graphics::strwidth("m", cex = cex) * 0.7; dy <- graphics::strheight("M", cex = cex) * 0.7
  ocup <- matrix(numeric(0), ncol = 4)
  solapa <- function(r) {
    if (r[1] < usr[1] || r[2] > usr[2] || r[3] < usr[3] || r[4] > usr[4]) return(TRUE)
    if (!nrow(ocup)) return(FALSE)
    any(r[1] < ocup[, 2] & r[2] > ocup[, 1] & r[3] < ocup[, 4] & r[4] > ocup[, 3])
  }
  orden <- order(!(seq_len(n) %in% resalta))
  for (i in orden) {
    cand <- list(c(4, x[i] + dx, x[i] + dx + w[i], y[i] - h / 2, y[i] + h / 2),
                 c(2, x[i] - dx - w[i], x[i] - dx, y[i] - h / 2, y[i] + h / 2),
                 c(3, x[i] - w[i] / 2, x[i] + w[i] / 2, y[i] + dy, y[i] + dy + h),
                 c(1, x[i] - w[i] / 2, x[i] + w[i] / 2, y[i] - dy - h, y[i] - dy))
    el <- NULL
    for (cd in cand) if (!solapa(cd[2:5])) { el <- cd; break }
    if (is.null(el)) el <- cand[[1]]
    ocup <- rbind(ocup, el[2:5])
    graphics::text(x[i], y[i], lab[i], pos = el[1], cex = cex, offset = 0.6,
                   font = if (i %in% resalta) 2 else 1, col = if (i %in% resalta) .COL_ROJO else "grey15")
  }
  invisible(NULL)
}

.fig_esov <- function(z, a = NULL, marca = NULL, resid = FALSE, jones = NULL,
                      sin = NULL, ref = FALSE) {
  op <- graphics::par(mar = c(4.4, 4.6, 1, 1.2), cex = 1.05); on.exit(graphics::par(op))
  xs <- c(0, z$som * 1.12)
  ys <- c(z$esov, 0)
  if (!is.null(a)) ys <- c(ys, a$alfa + a$beta * range(xs))
  if (!is.null(jones)) ys <- c(ys, jones[["alfa"]] + jones[["beta"]] * range(xs))
  graphics::plot(NA, xlim = range(xs), ylim = range(ys) + c(-0.05, 0.05) * diff(range(ys)),
                 xlab = "Cuota de mercado, SOM (%)", ylab = "ESOV = SOV - SOM (pp)", las = 1)
  graphics::abline(h = 0, lwd = 1.6)
  usr <- graphics::par("usr")
  graphics::text(usr[2], 0, "SOBREINVERSI\u00d3N (SOV > SOM) \u2191", adj = c(1, -0.6), cex = 0.7, col = .COL_ROJO, font = 2)
  graphics::text(usr[2], 0, "SUBINVERSI\u00d3N (SOV < SOM) \u2193", adj = c(1, 1.6), cex = 0.7, col = "grey30", font = 2)
  if (!is.null(jones)) graphics::abline(a = jones[["alfa"]], b = jones[["beta"]], lty = 2, lwd = 2, col = "grey45")
  if (!is.null(a)) {
    if (resid) graphics::segments(z$som, z$esov, z$som, a$alfa + a$beta * z$som, col = "grey40", lwd = 1.2)
    graphics::abline(a = a$alfa, b = a$beta, lwd = 2.4, col = .COL_ROJO)
  }
  if (!is.null(sin)) graphics::abline(a = sin$alfa, b = sin$beta, lwd = 2.4, lty = 3, col = "black")
  es_m <- if (!is.null(marca)) z$marca == marca else rep(FALSE, nrow(z))
  graphics::points(z$som[!es_m], z$esov[!es_m], pch = 19, col = "grey30", cex = 1.2)
  if (any(es_m)) graphics::points(z$som[es_m], z$esov[es_m], pch = 19, col = .COL_ROJO, cex = 1.9)
  if (!is.null(sin)) graphics::points(sin$som, sin$esov, pch = 1, cex = 2.6, lwd = 2)
  if (ref && any(es_m)) {
    if (!is.null(jones)) graphics::points(z$som[es_m], jones[["alfa"]] + jones[["beta"]] * z$som[es_m], pch = 1, cex = 1.9, lwd = 2, col = "grey45")
    if (!is.null(a)) graphics::points(z$som[es_m], a$alfa + a$beta * z$som[es_m], pch = 1, cex = 1.9, lwd = 2, col = "black")
  }
  .etiquetas(z$som, z$esov, z$marca, resalta = which(es_m))
  invisible(NULL)
}

.fig_mapa <- function(z, marca = NULL, jones = NULL, valores = FALSE, rotulos = NULL) {
  op <- graphics::par(mar = c(4.4, 4.6, 1, 1.2), cex = 1.05, pty = "s"); on.exit(graphics::par(op))
  lim <- c(0, max(z$som, z$sov) * 1.12)
  graphics::plot(NA, xlim = lim, ylim = lim, xlab = "Cuota de voz, SOV (%)", ylab = "Cuota de mercado, SOM (%)", las = 1)
  graphics::polygon(c(0, 0, lim[2]), c(0, lim[2], lim[2]), col = "#1a1a1a0d", border = NA)
  graphics::abline(0, 1, lwd = 2)
  graphics::text(lim[2] * 0.03, lim[2] * 0.97, "ZONA COSECHA\n(vende m\u00e1s de lo que habla)", adj = c(0, 1), cex = 0.7, font = 2, col = "grey30")
  graphics::text(lim[2] * 0.97, lim[2] * 0.03, "ZONA INVERSI\u00d3N\n(habla m\u00e1s de lo que vende)", adj = c(1, 0), cex = 0.7, font = 2, col = .COL_ROJO)
  if (!is.null(jones)) {
    # ESOV = a + b*SOM  <=>  SOV = a + (1 + b)*SOM  <=>  SOM = (SOV - a)/(1 + b)
    a <- unname(jones["alfa"]); b <- unname(jones["beta"])
    x1 <- a + (1 + b) * lim[2]
    graphics::segments(a, 0, x1, lim[2], col = .COL_ROJO, lty = 2, lwd = 2)
  }
  es_m <- if (is.null(marca)) rep(FALSE, nrow(z)) else z$marca == marca
  graphics::points(z$sov[!es_m], z$som[!es_m], pch = 19, col = "grey30", cex = 1.2)
  graphics::points(z$sov[es_m], z$som[es_m], pch = 19, col = .COL_ROJO, cex = 1.9)
  lab <- if (is.null(rotulos)) z$marca else rotulos
  if (valores) lab <- paste0(lab, "\nSOV ", fmt_es(z$sov, 1), " \u00b7 SOM ", fmt_es(z$som, 1))
  .etiquetas(z$sov, z$som, lab, resalta = which(es_m))
  invisible(NULL)
}

.fig_loo <- function(inf, a) {
  op <- graphics::par(mar = c(4.4, 8, 1, 1.2), cex = 1.05); on.exit(graphics::par(op))
  o <- order(inf$beta_sin); inf <- inf[o, ]
  y <- seq_len(nrow(inf))
  xl <- range(c(inf$beta_sin, a$beta, 0, a$ic_beta))
  graphics::plot(inf$beta_sin, y, xlim = xl, ylim = c(0.5, nrow(inf) + 0.5), pch = 19, col = "grey25",
                 cex = 1.4, yaxt = "n", ylab = "", xlab = "Pendiente \u03b2 recalculada sin esa marca")
  graphics::axis(2, at = y, labels = paste("sin", inf$marca), las = 1, tick = FALSE, cex.axis = 0.85)
  graphics::abline(v = 0, lty = 2, lwd = 1.6)
  graphics::abline(v = a$beta, lwd = 2.4, col = .COL_ROJO)
  graphics::legend("bottomright", c("con todas las marcas", "cero"), lty = c(1, 2), lwd = c(2.4, 1.6),
                   col = c(.COL_ROJO, "black"), bty = "n", cex = 0.8)
  invisible(NULL)
}

# ------------------------------------------------------------- utilidades
.g_localiza <- function(x, categoria) {
  ok <- Filter(function(s) !is.null(s$ajuste), x$sectores)
  if (!length(ok)) stop("Ninguna categor\u00eda tiene las 4 marcas necesarias para la gu\u00eda.", call. = FALSE)
  if (is.null(categoria)) return(ok[[1]])
  i <- which(names(ok) == categoria | vapply(ok, function(s) identical(s$sector, categoria), NA))
  if (!length(i)) stop("Categor\u00eda no encontrada o con menos de 4 marcas. Disponibles: ",
                       paste(names(ok), collapse = ", "), call. = FALSE)
  ok[[i[1]]]
}

.g_banner_sim <- function(x) {
  if (!isTRUE(x$simulado)) return("")
  paste0('<div class="sg-sim"><b>DATOS SINT\u00c9TICOS.</b> Los ejemplos num\u00e9ricos de esta gu\u00eda proceden de una simulaci\u00f3n ',
         "con par\u00e1metros conocidos: ilustran el m\u00e9todo, <b>no</b> describen ning\u00fan mercado real.</div>")
}

.g_signo <- function(a) {
  if (a$ic_beta[2] < 0) "neg" else if (a$ic_beta[1] > 0) "pos" else "cero"
}

.g_limites <- function(x, extra = NULL) {
  paste0('<div class="sg-warn"><b>L\u00edmites que deben recordarse.</b>', .g_ul(c(
    "<b>Tama\u00f1o muestral</b>: con pocas marcas por categor\u00eda, los intervalos y los valores p son orientativos.",
    "<b>Muestra truncada</b>: si solo figuran las marcas l\u00edderes, las peque\u00f1as, que definen \u03b1, quedan fuera.",
    "<b>Medida del SOV</b>: depende de lo que se contabilice (por ejemplo, medios medidos de un \u00fanico a\u00f1o), no de toda la comunicaci\u00f3n.",
    "<b>Medida del SOM</b>: la base cambia seg\u00fan el sector (unidades, ventas, suscriptores, volumen).",
    "<b>Relaci\u00f3n mec\u00e1nica</b>: SOM aparece en ambos lados de la ecuaci\u00f3n (ESOV = SOV \u2212 SOM); por eso \u03b2 se interpreta respecto a 0, no respecto a \u22121.",
    "<b>Causalidad</b>: es un corte transversal; describe asociaciones y no permite afirmar que invertir m\u00e1s <i>cause</i> ganar cuota.",
    extra)), "</div>")
}

# ----------------------------------------------------------------- GUÍA DEL SECTOR
.guia_sector <- function(x, categoria, marca, figuras = TRUE) {
  s <- .g_localiza(x, categoria)
  a <- s$ajuste; z <- s$datos; inf <- s$influencia; n <- a$n
  niv <- round(x$nivel * 100); tc <- stats::qt(1 - (1 - x$nivel) / 2, a$gl)
  jb <- unname(x$jones["beta"]); ja <- unname(x$jones["alfa"])
  if (is.null(marca)) marca <- z$marca[which.max(z$som)]
  if (!(marca %in% z$marca)) stop("Marca no encontrada en la categor\u00eda. Disponibles: ", paste(z$marca, collapse = ", "), call. = FALSE)
  fig <- function(...) if (isTRUE(figuras)) .png_uri(...) else ""
  signo <- .g_signo(a)
  k <- min(3, floor(n / 2))
  o <- order(-z$som); grandes <- z[o[seq_len(k)], ]; peques <- z[rev(o)[seq_len(k)], ]
  pasos <- list()

  # 1
  m1 <- mean(grandes$esov); m2 <- mean(peques$esov)
  dir <- if (m1 < m2 - 1e-9) "La nube <b>desciende de izquierda a derecha</b>." else if (m1 > m2 + 1e-9) "La nube <b>asciende de izquierda a derecha</b>." else "La nube es <b>plana</b>."
  pasos[[1]] <- list("Cada marca es un punto: exceso de voz frente a cuota", c(
    .g_p("Cada marca aporta dos datos: su <b>cuota de mercado</b> (SOM) y su <b>exceso de voz</b> (ESOV = SOV \u2212 SOM)."),
    .g_ul(c("<b>Eje horizontal</b>: SOM, el tama\u00f1o de la marca.",
            "<b>Eje vertical</b>: ESOV, cu\u00e1nto habla de m\u00e1s o de menos respecto a lo que vende.",
            "<b>L\u00ednea horizontal en 0</b>: SOV = SOM. Por encima, <b>sobreinversi\u00f3n</b>; por debajo, <b>subinversi\u00f3n</b>.")),
    fig(function() .fig_esov(z, marca = marca), paste0("Diagrama de dispersi\u00f3n del ESOV frente al SOM de las ", n, " marcas de ", s$sector),
        paste0(s$sector, ": cada punto es una marca. Eje vertical: lo que habla de m\u00e1s (+) o de menos (\u2212) respecto a lo que vende.")),
    .g_q("\u00bfSe aprecia alg\u00fan patr\u00f3n a simple vista?",
         .g_p("Las ", k, " marcas de mayor cuota (", .lista_es(grandes$marca), ") tienen un ESOV medio de <b>", .pp(m1), "</b>; las ", k,
              " de menor cuota (", .lista_es(peques$marca), "), de <b>", .pp(m2), "</b>. ", dir, " Falta cuantificar esa pendiente."))))

  # 2
  i_m <- which(inf$marca == marca)
  pred <- a$alfa + a$beta * z$som[z$marca == marca]
  pasos[[2]] <- list("De los puntos a la recta: m\u00ednimos cuadrados", c(
    .g_p("\u00bfQu\u00e9 recta resume mejor esta nube? La que pasa <b>lo m\u00e1s cerca posible</b> de todos los puntos. Para medir \u00abcerca\u00bb se usa el <b>residuo</b>: la distancia vertical entre una marca y la recta."),
    .g_eq("ESOV<sub>i</sub> = \u03b1 + \u03b2 \u00b7 SOM<sub>i</sub> + \u03b5<sub>i</sub>"),
    .g_ul(c("<b>\u03b1</b> (intercepto): el punto donde la recta corta el eje vertical.",
            "<b>\u03b2</b> (pendiente): cu\u00e1nto cambia el ESOV por cada punto m\u00e1s de cuota.",
            "<b>\u03b5<sub>i</sub></b> (residuo): lo que la recta no explica de la marca <i>i</i>.")),
    .g_p("El m\u00e9todo de <b>m\u00ednimos cuadrados ordinarios</b> (MCO) elige \u03b1 y \u03b2 de modo que la suma de los residuos al cuadrado sea la menor posible. En ", s$sector, " resulta:"),
    .g_eq(paste0("ESOV estimado = ", fmt_es(a$alfa, 2, TRUE), if (a$beta < 0) " \u2212 " else " + ", fmt_es(abs(a$beta), 2), " \u00b7 SOM")),
    fig(function() .fig_esov(z, a, marca, resid = TRUE, jones = x$jones), paste0("Recta de m\u00ednimos cuadrados con residuos en ", s$sector),
        "L\u00ednea roja: recta de m\u00ednimos cuadrados. Segmentos grises: residuos. Gris discontinua: aproximaci\u00f3n lineal a la tabla de Jones."),
    .g_p("Ejemplo con <b>", .html_esc(marca), "</b>: la recta predice un ESOV de ", .pp(pred), "; el real es ", .pp(z$esov[z$marca == marca]),
         ". Su residuo es <b>", .pp(inf$residuo[i_m]), "</b>: ",
         if (inf$residuo[i_m] > 0) "habla algo m\u00e1s de lo que la recta de su categor\u00eda esperar\u00eda." else if (inf$residuo[i_m] < 0) "habla algo menos de lo que la recta de su categor\u00eda esperar\u00eda." else "coincide con lo que la recta espera.")))

  # 3
  som_min <- min(z$som)
  umbral <- if (is.finite(a$som_umbral)) paste0("<li><b>SOM* = \u2212\u03b1/\u03b2 \u2248 ", .pc(a$som_umbral), "</b>: la cuota a partir de la cual la recta predice un ESOV ", if (a$beta < 0) "negativo." else "positivo.", "</li>") else ""
  pasos[[3]] <- list("Leer la recta: qu\u00e9 dicen \u03b1 y \u03b2", c(
    paste0("<ul><li><b>\u03b2\u0302 = ", fmt_es(a$beta, 2), "</b>: por cada punto m\u00e1s de cuota, el ESOV ", if (a$beta < 0) "baja " else "sube ",
           fmt_es(abs(a$beta), 2), " puntos. Dicho de otro modo, el SOV sube <b>", fmt_es(1 + a$beta, 2), "</b> puntos por cada punto de cuota (1 + \u03b2\u0302).</li>",
           "<li><b>\u03b1\u0302 = ", fmt_es(a$alfa, 2, TRUE), "</b>: el ESOV que la recta asigna a una marca de cuota casi nula. La marca m\u00e1s peque\u00f1a de la muestra tiene un SOM de ",
           .pc(som_min), "; lo que ocurre por debajo es una <b>extrapolaci\u00f3n</b>.</li>", umbral, "</ul>"),
    .g_p("El signo de \u03b2 cuenta una historia distinta en cada caso:"),
    .g_tbl(.renombra(data.frame(a = c("Negativa (\u03b2 < 0)", "Cero (\u03b2 = 0)", "Positiva (\u03b2 > 0)", "\u03b2 = \u22121"),
                      b = c("Econom\u00eda de escala: las grandes invierten proporcionalmente menos.",
                                  "Todas las marcas tienen el mismo exceso: SOV = SOM + \u03b1.",
                                  "Deseconom\u00eda: las grandes invierten proporcionalmente m\u00e1s.",
                                  "El SOV no guarda relaci\u00f3n con el tama\u00f1o (efecto mec\u00e1nico, porque SOM aparece en ambos lados)."),
                      stringsAsFactors = FALSE), c("Si \u03b2 es\u2026", "Lectura"))),
    .g_res(paste0("En ", .html_esc(s$sector), ", la pendiente (", fmt_es(a$beta, 2), ") se compara con la de la aproximaci\u00f3n lineal a Jones (", fmt_es(jb, 2),
                  "); el intercepto (", fmt_es(a$alfa, 2, TRUE), ") con el de Jones (", fmt_es(ja, 1, TRUE), ")."))))

  # 4
  lo3 <- a$ic_beta_hc3
  hc3 <- if (all(is.finite(lo3))) paste0("<li><b>Intervalo robusto (HC3)</b> = [", fmt_es(lo3[1], 2), "; ", fmt_es(lo3[2], 2), "] (p = ", fmt_p(a$p_beta_hc3),
                                         "): no supone que la dispersi\u00f3n de los errores sea igual para todas las marcas, algo que en cuotas rara vez se cumple. Si difiere mucho del cl\u00e1sico, f\u00edese m\u00e1s del robusto.</li>") else ""
  bt <- if (length(s$bootstrap$p_neg) == 1 && is.finite(s$bootstrap$p_neg)) paste0("<li><b>Bootstrap de pares</b> (", s$bootstrap$B_validas, " remuestras): intervalo percentil [", fmt_es(s$bootstrap$ols[1], 2), "; ", fmt_es(s$bootstrap$ols[2], 2),
                                                 "]; la pendiente es negativa en el <b>", fmt_es(100 * s$bootstrap$p_neg, 0), " %</b> de las remuestras.</li>") else ""
  dentro <- jb >= a$ic_beta[1] && jb <= a$ic_beta[2]
  ia_cero <- a$ic_alfa[1] <= 0 && a$ic_alfa[2] >= 0
  concl <- switch(signo,
    neg = paste0("En ", .html_esc(s$sector), " hay evidencia de <b>econom\u00eda de escala</b>. Pero con ", n, " marcas, un solo punto podr\u00eda torcer la recta. Eso se comprueba en los pasos siguientes."),
    pos = paste0("En ", .html_esc(s$sector), " hay evidencia de <b>deseconom\u00eda de escala</b> (las grandes invierten proporcionalmente m\u00e1s). Con ", n, " marcas, queda comprobar que no depende de una sola."),
    cero = paste0("En ", .html_esc(s$sector), " el intervalo incluye el 0: <b>no hay evidencia</b> de que el ESOV dependa de la cuota. Eso no demuestra que no exista relaci\u00f3n, solo que estos datos no la detectan."))
  pasos[[4]] <- list("\u00bfCu\u00e1nta confianza merece la pendiente?", c(
    .g_p("Con ", n, " marcas, otra muestra de ", n, " marcas dar\u00eda otra recta. Varias cifras ayudan a calibrar cu\u00e1nto fiarse de \u03b2\u0302 = ", fmt_es(a$beta, 2), "."),
    paste0("<ul><li><b>Error est\u00e1ndar</b> = ", fmt_es(a$se_beta, 2), ": cu\u00e1nto se mover\u00eda \u03b2\u0302 de una muestra a otra.</li>",
           "<li><b>Intervalo de confianza al ", niv, " %</b> = [", fmt_es(a$ic_beta[1], 2), "; ", fmt_es(a$ic_beta[2], 2), "]: valores razonablemente compatibles con los datos. ",
           if (signo == "cero") "<b>Incluye el 0</b>: no se distingue de ninguna pendiente nula." else "<b>No incluye el 0</b>: hay evidencia de pendiente ", if (signo == "neg") "negativa." else if (signo == "pos") "positiva.", "</li>",
           "<li><b>Valor p</b> = ", fmt_p(a$p_beta), ": probabilidad de obtener una pendiente tan alejada de 0 solo por azar, si la pendiente real fuera 0.</li>",
           "<li><b>R\u00b2</b> = ", fmt_es(a$r2, 2), ": la recta explica el ", fmt_es(100 * a$r2, 0), " % de la variaci\u00f3n del ESOV entre marcas.</li>", hc3, bt, "</ul>"),
    .g_note(paste0("Los grados de libertad son ", a$gl, " (", n, " marcas menos 2 par\u00e1metros). Con pocos datos el intervalo se ensancha: se usa una <i>t</i> de ", fmt_es(tc, 2), " en lugar de 1,96.")),
    .g_q(paste0("\u00bfCae el ", fmt_es(jb, 2), " de Jones dentro del intervalo?"),
         .g_p(if (dentro) "S\u00ed. La recta de Jones es compatible con la pendiente de esta categor\u00eda." else "No. La pendiente de esta categor\u00eda es incompatible con la de la aproximaci\u00f3n lineal a Jones.")),
    .g_warn(paste0("<b>Y el intercepto, \u00bfes fiable?</b> Su intervalo va de ", fmt_es(a$ic_alfa[1], 2), " a ", fmt_es(a$ic_alfa[2], 2),
                   if (ia_cero) " e incluye el 0: no se distingue de cero. Es esperable si solo figuran las marcas l\u00edderes, porque las peque\u00f1as, que definen \u03b1, quedan fuera." else ". No incluye el 0, pero sigue siendo una extrapolaci\u00f3n si no hay marcas muy peque\u00f1as.")),
    .g_res(concl)))

  # 5
  ok <- Filter(function(t) !is.null(t$ajuste), x$sectores)
  if (length(ok) >= 2) {
    cls <- vapply(ok, function(t) .g_signo(t$ajuste), "")
    nm <- function(w) .lista_es(vapply(ok[cls == w], function(t) paste0(.html_esc(t$sector), " (n = ", t$ajuste$n, ")"), ""))
    lect <- c(if (any(cls == "neg")) paste0("<b>Pendiente negativa</b> (el intervalo no incluye el 0): ", nm("neg"), "."),
              if (any(cls == "pos")) paste0("<b>Pendiente positiva</b>: las grandes invierten proporcionalmente <i>m\u00e1s</i>, lo contrario de la curva AI: ", nm("pos"), "."),
              if (any(cls == "cero")) paste0("<b>Sin evidencia de pendiente</b> (el intervalo incluye el 0): ", nm("cero"), "."),
              if (any(vapply(ok, function(t) t$ajuste$n <= 6, NA))) "Las categor\u00edas con seis marcas o menos tienen intervalos muy anchos.",
              "La recta <b>cambia de una categor\u00eda a otra</b>.")
    het <- x$heterogeneidad
    hettxt <- if (!is.null(het)) paste0("El contraste F de pendientes comunes da F(", het$gl1, ", ", het$gl2, ") = ", fmt_es(het$F, 2), " (p = ", fmt_p(het$p), "): ",
                                        if (het$p < 0.05) "se <b>rechaza</b> que todas las categor\u00edas compartan la misma pendiente." else "no se rechaza que compartan pendiente, aunque con pocas marcas el contraste tiene poca potencia.") else ""
    tr <- sov_tabla(x, "resultados")
    tr <- tr[, c(1, 2, 3, 4, 6, 8, 9), drop = FALSE]
    pasos[[5]] <- list("Comparar las categor\u00edas", c(
      .g_p("Si se repite el mismo c\u00e1lculo en cada categor\u00eda y se dibuja la pendiente con su intervalo, aparece el siguiente gr\u00e1fico."),
      fig(function() sov_grafico_bosque(x), "Pendiente estimada con su intervalo de confianza en cada categor\u00eda",
          paste0("Cada categor\u00eda: pendiente \u03b2 con su intervalo al ", niv, " %. Un c\u00edrculo relleno indica significaci\u00f3n al 5 %."), h = 4),
      .g_tbl(tr),
      .g_p("Lecturas:"), .g_ul(lect),
      .g_q("Entonces, \u00bfexiste una curva universal?",
           .g_p(hettxt, " Danenberg et al. (2016) concluyen que la curva debe <b>calibrarse por industria</b>; esta comparaci\u00f3n va en la misma direcci\u00f3n.")))) 
  } else {
    pasos[[5]] <- list("Comparar las categor\u00edas", c(.g_p("Estos datos contienen una sola categor\u00eda con las marcas necesarias, de modo que no hay otras con las que comparar. Con varias categor\u00edas, el informe dibujar\u00eda aqu\u00ed la pendiente de cada una con su intervalo y contrastar\u00eda si comparten pendiente.")))
  }

  # 6
  d_beta <- abs(inf$beta_sin - a$beta); im <- which.max(d_beta)
  rg <- a$loo_rango; cambia <- rg[1] < 0 && rg[2] > 0
  pasos[[6]] <- list("\u00bfManda una sola marca? La prueba de \u00abdejar una fuera\u00bb", c(
    .g_p("Es la idea central del <b>an\u00e1lisis de sensibilidad</b>: si el resultado depende de una marca, no es un resultado sobre la categor\u00eda, sino sobre esa marca."),
    .g_ul(c("Se <b>quita una marca</b> y se recalcula la pendiente.", paste0("Se repite con cada una de las ", n, "."),
            "Se anota qu\u00e9 valor toma \u03b2 en cada caso: la \u00ab<b>\u03b2 sin ella</b>\u00bb (<i>leave-one-out</i>).")),
    fig(function() .fig_loo(inf, a), paste0("Pendiente recalculada al omitir cada marca de ", s$sector),
        "Cada punto es la pendiente recalculada sin esa marca. L\u00ednea roja: pendiente con todas las marcas; l\u00ednea discontinua: cero."),
    .g_p("En ", .html_esc(s$sector), ", \u03b2\u0302 oscila entre <b>", fmt_es(rg[1], 2), "</b> y <b>", fmt_es(rg[2], 2), "</b>. ",
         if (cambia) "<b>Cambia de signo</b> seg\u00fan qu\u00e9 marca se quite. " else "Nunca cambia de signo. ",
         "La marca cuya ausencia m\u00e1s la mueve es <b>", .html_esc(inf$marca[im]), "</b>: sin ella, \u03b2\u0302 pasa de ", fmt_es(a$beta, 2), " a ", fmt_es(inf$beta_sin[im], 2), "."),
    .g_res(if (cambia) paste0("La conclusi\u00f3n de ", .html_esc(s$sector), " <b>no es estable</b>: depende de qu\u00e9 marcas se incluyan.") else paste0("El <b>signo</b> de la pendiente de ", .html_esc(s$sector), " es <b>estable</b>: no depende de ninguna marca concreta.", if (signo == "cero") " Pero recuerde que el intervalo incluye el 0." else ""))))

  # 7
  hlim <- 4 / n; dlim <- 4 / n; dfl <- 2 / sqrt(n)
  P <- inf$marca[inf$alerta_P]; A <- inf$marca[inf$alerta_A]; I <- inf$marca[inf$alerta_I]
  infl_norm <- inf$marca[inf$alerta_I & !inf$alerta_A]; at_sin <- inf$marca[inf$alerta_A & !inf$alerta_I]
  ti <- sov_tabla(x, "influencia", categoria = s$caso)[, -1, drop = FALSE]
  resumen <- paste0("En ", .html_esc(s$sector), ": alerta <b>P</b> en ", if (length(P)) .lista_es(.html_esc(P)) else "ninguna marca",
                    "; alerta <b>A</b> en ", if (length(A)) .lista_es(.html_esc(A)) else "ninguna marca",
                    "; alerta <b>I</b> en ", if (length(I)) .lista_es(.html_esc(I)) else "ninguna marca", ".")
  ej <- c(if (length(infl_norm)) paste0("Una marca puede ser <b>influyente y perfectamente normal</b>: ", .html_esc(infl_norm[1]), " tiene un residuo studentizado de ", fmt_es(inf$t_stud[inf$marca == infl_norm[1]], 2), ", pero condiciona la pendiente por su posici\u00f3n."),
          if (length(at_sin)) paste0("Y una marca puede ser <b>at\u00edpica sin influir</b>: ", .html_esc(at_sin[1]), " tiene |t*| = ", fmt_es(abs(inf$t_stud[inf$marca == at_sin[1]]), 2), ", pero su distancia de Cook es solo ", fmt_es(inf$cook[inf$marca == at_sin[1]], 2), "."))
  if (!length(ej)) ej <- "Una marca puede ser <b>influyente y normal</b> (su posici\u00f3n condiciona la recta aunque su residuo sea peque\u00f1o) o <b>at\u00edpica sin influir</b> (su residuo es grande, pero su cuota es central). En estos datos no aparece ninguno de los dos casos."
  pasos[[7]] <- list("Cuatro diagn\u00f3sticos para saber qu\u00e9 marca influye", c(
    .g_p("Adem\u00e1s de quitar marcas, hay cuatro medidas que describen el papel de cada una. Se leen mejor con una pregunta cada una."),
    .g_ul(c(paste0("<b>Palanca (h)</b>: \u00bfest\u00e1 la cuota de esta marca lejos de la cuota media de la categor\u00eda? Una marca muy distinta del resto \u00abtira\u00bb de la recta. Alerta <b>P</b> si h &gt; 4/n."),
            "<b>Residuo studentizado (t*)</b>: \u00bfqueda su ESOV lejos de la recta? Mide cu\u00e1ntos errores t\u00edpicos se aparta (calculado sin esa marca). Alerta <b>A</b> (at\u00edpica) si |t*| &gt; 2.",
            "<b>Distancia de Cook (D)</b>: \u00bfcu\u00e1nto cambia el ajuste completo si se omite esta marca? Combina palanca y residuo. Alerta <b>I</b> (influyente) si D &gt; 4/n.",
            "<b>DFBETAS</b>: \u00bfcu\u00e1nto cambia la pendiente, medido en errores est\u00e1ndar, si se omite? Tambi\u00e9n activa la alerta <b>I</b> si |DFBETAS| &gt; 2/\u221an.")),
    .g_p("Para <i>n</i> = ", n, ", los umbrales son: h &gt; ", fmt_es(hlim, 2), "; |t*| &gt; 2; D &gt; ", fmt_es(dlim, 2), "; |DFBETAS| &gt; ", fmt_es(dfl, 2), "."),
    .g_tbl(ti, hl = inf$alerta != ""), .g_p(resumen),
    .g_q("\u00bfEs lo mismo una marca at\u00edpica que una marca influyente?", .g_p("No. ", paste(ej, collapse = " "))),
    .g_res("Las alertas son <b>umbrales orientativos</b>, no veredictos. Lo decisivo es si cambia la conclusi\u00f3n: comp\u00e1rese siempre con la columna \u00ab\u03b2 sin la marca\u00bb.")))

  # 8
  ts <- a$ts_beta; mism <- sign(ts) == sign(a$beta)
  pasos[[8]] <- list("Una alternativa robusta: la pendiente de Theil\u2013Sen", c(
    .g_p("Es otra manera de calcular la pendiente, que <b>no se deja arrastrar por valores extremos</b>."),
    .g_ul(c(paste0("Se toman las marcas <b>de dos en dos</b>: con ", n, " marcas hay ", choose(n, 2), " parejas."), "Cada pareja define una pendiente.", paste0("Se toma la <b>mediana</b> de esas ", choose(n, 2), " pendientes."))),
    .g_p("En ", .html_esc(s$sector), ", Theil\u2013Sen da <b>", fmt_es(ts, 2), "</b>, frente a ", fmt_es(a$beta, 2), " por m\u00ednimos cuadrados. ",
         if (mism) "Los dos tienen el mismo signo." else "<b>Tienen signos distintos.</b>"),
    .g_q("\u00bfQu\u00e9 significa que coincidan en el signo?",
         .g_p(if (mism) "Que la pendiente no es un artefacto de los valores extremos. Si ambas difirieran mucho, habr\u00eda que desconfiar de la recta de m\u00ednimos cuadrados." else "Que los valores extremos est\u00e1n arrastrando la recta de m\u00ednimos cuadrados. Desconf\u00ede de ella y de su intervalo."))))

  # 9
  inest <- Filter(function(t) !is.null(t$ajuste) && t$ajuste$loo_rango[1] < 0 && t$ajuste$loo_rango[2] > 0, x$sectores)
  inest <- Filter(function(t) !identical(t$caso, s$caso), inest)
  if (length(inest)) {
    t0 <- inest[[1]]; a0 <- t0$ajuste; i0 <- t0$influencia; j <- which.max(abs(i0$beta_sin - a0$beta))
    z0 <- t0$datos; sin0 <- sov_ajusta(z0$som[-j], z0$esov[-j], x$nivel)
    otras <- z0$som[-j]
    cuerpo9 <- c(.g_p("Es el caso que muestra por qu\u00e9 el an\u00e1lisis de sensibilidad es imprescindible: ", .html_esc(t0$sector), "."),
      fig(function() .fig_esov(z0, a0, z0$marca[j], sin = list(alfa = sin0$alfa, beta = sin0$beta, som = z0$som[j], esov = z0$esov[j])),
          paste0("Recta con y sin ", z0$marca[j], " en ", t0$sector), paste0(.html_esc(t0$sector), ". Roja: recta con todas las marcas. Negra punteada: recta sin ", .html_esc(z0$marca[j]), " (marca rodeada).")),
      .g_ul(c(paste0("Con las ", a0$n, " marcas, la pendiente es <b>", fmt_es(a0$beta, 2, TRUE), "</b> (IC [", fmt_es(a0$ic_beta[1], 2), "; ", fmt_es(a0$ic_beta[2], 2), "]; p = ", fmt_p(a0$p_beta), ")."),
              paste0("Sin ", .html_esc(z0$marca[j]), ", la pendiente pasa a <b>", fmt_es(sin0$beta, 2, TRUE), "</b> (IC [", fmt_es(sin0$ic_beta[1], 2), "; ", fmt_es(sin0$ic_beta[2], 2), "]; p = ", fmt_p(sin0$p_beta), ")."),
              paste0("La \u00ab\u03b2 sin ella\u00bb oscila entre <b>", fmt_es(a0$loo_rango[1], 2), "</b> y <b>", fmt_es(a0$loo_rango[2], 2), "</b>: <b>cambia de signo</b> seg\u00fan se incluya o no una sola marca."))),
      .g_p(.html_esc(z0$marca[j]), " tiene una cuota de ", .pc(z0$som[j]), " y las dem\u00e1s est\u00e1n entre ", .pc(min(otras)), " y ", .pc(max(otras)), ". Sus diagn\u00f3sticos: palanca h = <b>", fmt_es(i0$palanca[j], 2),
           "</b> (umbral ", fmt_es(4 / a0$n, 2), "), distancia de Cook D = <b>", fmt_es(i0$cook[j], 2), "</b> (umbral ", fmt_es(4 / a0$n, 2), "), DFBETAS = <b>", fmt_es(i0$dfbetas[j], 2), "</b> (umbral ", fmt_es(2 / sqrt(a0$n), 2), ")."),
      .g_q("Entonces, \u00bfqu\u00e9 se concluye de esta categor\u00eda?", .g_p("Que <b>no hay base</b> para afirmar ni econom\u00eda de escala ni lo contrario: la pendiente depende de una sola marca. Theil\u2013Sen (", fmt_es(a0$ts_beta, 2, TRUE), ") ofrece una segunda opini\u00f3n.")))
  } else {
    cuerpo9 <- c(.g_p("El an\u00e1lisis de sensibilidad es imprescindible porque a veces <b>una sola marca decide el signo</b> de la pendiente: si al quitarla la pendiente pasa de positiva a negativa (o al rev\u00e9s), no hay base para concluir nada sobre la categor\u00eda."),
                 .g_p("En estos datos, <b>ninguna otra categor\u00eda</b> cambia de signo al omitir una marca; el paso 6 le indica d\u00f3nde mirar si trabaja con otros datos."))
  }
  pasos[[9]] <- list("Cuando una marca decide el signo", cuerpo9)

  # 10
  fl <- do.call(rbind, lapply(Filter(function(t) !is.null(t$ajuste), x$sectores), function(t) t$formas))
  nsec <- length(unique(vapply(Filter(function(t) !is.null(t$ajuste), x$sectores), function(t) t$caso, "")))
  ln_r <- sum(fl$mejor_rmse & fl$forma == "ln SOM"); ln_a <- sum(fl$mejor_aicc & fl$forma == "ln SOM")
  cu_r <- sum(fl$mejor_rmse & fl$forma == "Cuadr\u00e1tica"); li_r <- sum(fl$mejor_rmse & fl$forma == "Lineal")
  tf <- sov_tabla(x, "formas", categoria = s$caso)[, -1, drop = FALSE]
  pasos[[10]] <- list("\u00bfRecta o curva?", c(
    .g_p("La recta es una aproximaci\u00f3n c\u00f3moda, no una ley. Hay razones habituales para sospechar que la forma real es curva:"),
    .g_ul(c("El SOV y el SOM son <b>cuotas</b>: est\u00e1n entre 0 y 100 y suman 100. Una recta no respeta esos l\u00edmites.",
            "La respuesta de las ventas a la publicidad suele tener <b>rendimientos decrecientes</b> (curva c\u00f3ncava).",
            "Las marcas grandes tienden a tener <b>elasticidades publicitarias menores</b>.")),
    .g_p("Se comparan tres formas: lineal, logar\u00edtmica (ln SOM) y cuadr\u00e1tica, con validaci\u00f3n cruzada dejando una marca fuera (RMSE) y el criterio AICc (menor = mejor). En ", .html_esc(s$sector), ":"),
    .g_tbl(tf),
    .g_p("En el conjunto de ", nsec, " categor\u00edas, la forma logar\u00edtmica obtiene el menor RMSE de validaci\u00f3n cruzada en <b>", ln_r, "</b> y el menor AICc en <b>", ln_a, "</b>; la cuadr\u00e1tica, el menor RMSE en <b>", cu_r, "</b>; la lineal, en <b>", li_r, "</b>. La cuadr\u00e1tica siempre mejora el ajuste dentro de la muestra, pero eso no significa que prediga mejor."),
    .g_res(if (max(vapply(x$sectores, function(t) t$n, 1)) <= 12) "Con pocas marcas por categor\u00eda, los datos <b>no permiten imponer una curva</b>. La pr\u00e1ctica razonable: conservar la recta, usar ln SOM como comprobaci\u00f3n y apoyarse en Theil\u2013Sen." else "Compare las formas antes de elegir; con muchas marcas, una curva puede estar justificada si mejora la validaci\u00f3n cruzada de forma consistente.")))

  # 11
  pasos[[11]] <- list("Reproduzca el an\u00e1lisis en R", c(
    .g_p("Todo lo anterior se obtiene con unas pocas \u00f3rdenes:"),
    paste0("<pre><code>library(mediaSOV)\nx &lt;- sov_analiza(\"sus_datos.csv\")\nsov_grafico(x, \"", .html_esc(s$caso), "\")\nsov_tabla(x, \"influencia\", categoria = \"", .html_esc(s$caso), "\")\ncat(sov_interpreta(x), sep = \"\\n\\n\")</code></pre>"),
    .g_p("O bien <code>sov_asistente()</code>, que lo hace sin escribir c\u00f3digo.")))

  N <- length(pasos)
  hilo <- .g_ul(c("<b>Dibujar</b> cada marca como un punto.", "<b>Trazar</b> la recta que mejor las resume.", "<b>Medir</b> cu\u00e1nta confianza merece su pendiente.",
                  "<b>Comparar</b> las categor\u00edas.", "<b>Someter a prueba</b> el resultado: \u00bfmanda una sola marca? (an\u00e1lisis de sensibilidad).", "<b>Decidir</b> qu\u00e9 se puede concluir y qu\u00e9 no."))
  intro <- c('<div class="sg-root">', .g_banner_sim(x),
    '<p class="sg-intro">Esta gu\u00eda responde a <b>una sola pregunta</b>: \u00bfpodemos fiarnos de una recta calculada con pocas marcas?</p>',
    "<p>Aqu\u00ed se <b>estima la recta dentro de cada categor\u00eda</b> con los datos y, despu\u00e9s, se comprueba si el resultado <b>resiste</b> cuando se quita una marca. El hilo es este:</p>", hilo,
    paste0('<p class="sg-note"><b>Ejemplo gu\u00eda.</b> ', .html_esc(s$sector), ": ", n, " marcas (", .lista_es(.html_esc(z$marca)), "). El informe repite el an\u00e1lisis para el resto de categor\u00edas.</p>"))
  cuerpo <- vapply(seq_along(pasos), function(i) .g_step(i, N, pasos[[i]][[1]], pasos[[i]][[2]]), "")
  resumen <- paste0('<section class="sg-s"><div class="sg-step">Resumen</div><h4 class="sg-h">La cadena de razonamiento completa</h4>',
    .g_ol(c(paste0("<b>Dibujar</b> ESOV frente a SOM."),
            paste0("<b>Trazar</b> la recta por m\u00ednimos cuadrados: ", fmt_es(a$alfa, 2, TRUE), " y ", fmt_es(a$beta, 2), " en ", .html_esc(s$sector), "."),
            "<b>Interpretar</b> \u03b2: negativa, econom\u00eda de escala; positiva, deseconom\u00eda.",
            paste0("<b>Calibrar</b> la confianza con el intervalo (", fmt_es(a$ic_beta[1], 2), "; ", fmt_es(a$ic_beta[2], 2), "), el valor p y R\u00b2."),
            "<b>Comparar</b> categor\u00edas: la recta cambia de una a otra.",
            "<b>Someter a prueba</b>: dejar una marca fuera, diagn\u00f3sticos de influencia y Theil\u2013Sen.",
            "<b>Concluir</b> solo lo que resiste.")),
    .g_limites(x), "</section></div>")
  paste(c(intro, cuerpo, resumen), collapse = "\n")
}

# ------------------------------------------------------------------ GUÍA DE LA MARCA
.guia_marca <- function(x, categoria, marca, epsilon, anios, inversion, figuras = TRUE) {
  s <- .g_localiza(x, categoria)
  a <- s$ajuste; z <- s$datos; n <- nrow(z)
  jb <- unname(x$jones["beta"]); ja <- unname(x$jones["alfa"])
  if (is.null(marca)) marca <- z$marca[which.max(z$som)]
  if (!(marca %in% z$marca)) stop("Marca no encontrada en la categor\u00eda. Disponibles: ", paste(z$marca, collapse = ", "), call. = FALSE)
  fig <- function(...) if (isTRUE(figuras)) .png_uri(...) else ""
  r <- z[z$marca == marca, ]; M <- .html_esc(marca)
  rk <- rank(-z$som, ties.method = "min")[z$marca == marca]
  delante <- z$marca[order(-z$som)][seq_len(min(2, rk - 1))]
  delante_t <- if (rk > 1) paste0(" por detr\u00e1s de ", .lista_es(vapply(delante, function(m) paste0(.html_esc(m), " (", .pc(z$som[z$marca == m]), ")"), ""))) else ""
  sov_ref <- r$som + (ja + jb * r$som); gap_j <- r$sov - sov_ref
  esp <- a$alfa + (1 + a$beta) * r$som; gap_s <- r$sov - esp
  pasos <- list()
  pasos[[1]] <- list("Lo que vende: la cuota de mercado (SOM)", c(
    .g_p("La <b>cuota de mercado</b> (<i>share of market</i>, SOM) es el peso de una marca en las ventas de su categor\u00eda."),
    .g_ul(c(paste0("De cada 100 unidades vendidas en ", .html_esc(s$sector), ", <b>", fmt_es(r$som, 1), "</b> corresponden a ", M, "."),
            paste0("Es la marca n.\u00ba ", rk, " de las ", n, " analizadas", if (rk > 1) paste0(",", delante_t), "."))),
    .g_res(paste0("SOM de ", M, " = <b>", .pc(r$som), "</b>."))))
  pasos[[2]] <- list("Lo que habla: la cuota de voz (SOV)", c(
    .g_p("La <b>cuota de voz</b> (<i>share of voice</i>, SOV) es el peso de una marca en la inversi\u00f3n publicitaria de su categor\u00eda. Mide cu\u00e1nto \u00abruido\u00bb hace frente a las dem\u00e1s."),
    .g_eq("SOV = inversi\u00f3n de la marca / inversi\u00f3n de la categor\u00eda \u00d7 100"),
    .g_p("En estos datos el SOV ya viene calculado: de cada 100 unidades de publicidad de la categor\u00eda, <b>", fmt_es(r$sov, 1), "</b> son de ", M, "."),
    .g_res(paste0("SOV de ", M, " = <b>", .pc(r$sov), "</b>."))))
  pasos[[3]] <- list("\u00bfHabla m\u00e1s o menos de lo que vende? El exceso de voz (ESOV)", c(
    .g_p("Basta comparar las dos cuotas. La diferencia se llama <b>exceso de voz</b> (<i>excess share of voice</i>, ESOV) y se expresa en <b>puntos porcentuales</b> (pp)."),
    .g_eq(paste0("ESOV = SOV \u2212 SOM = ", fmt_es(r$sov, 1), " \u2212 ", fmt_es(r$som, 1), " = ", fmt_es(r$esov, 1), " pp")),
    .g_ul(c("<b>ESOV &gt; 0</b>: la marca habla m\u00e1s de lo que vende.", "<b>ESOV &lt; 0</b>: la marca habla menos de lo que vende.", "<b>ESOV = 0</b>: habla exactamente lo que vende.")),
    .g_q("\u00bfEs malo hablar menos de lo que se vende?", .g_p("Todav\u00eda no podemos saberlo. Para juzgarlo necesitamos una <b>referencia</b>: qu\u00e9 es \u00abnormal\u00bb para una marca de este tama\u00f1o. La construiremos en los pasos 6 a 8.")),
    .g_res(paste0("ESOV de ", M, " = <b>", .pp(r$esov), "</b>: ", if (r$esov < 0) "habla algo menos de lo que vende." else if (r$esov > 0) "habla m\u00e1s de lo que vende." else "habla exactamente lo que vende."))))
  pasos[[4]] <- list("El mapa: cada marca es un punto", c(
    .g_p("El mapa coloca cada marca seg\u00fan sus dos cuotas."),
    .g_ul(c("<b>Eje horizontal</b>: SOV (lo que habla).", "<b>Eje vertical</b>: SOM (lo que vende).", "<b>Diagonal</b>: los puntos donde SOV = SOM, es decir, ESOV = 0.")),
    fig(function() .fig_mapa(z, marca), paste0("Mapa SOV por SOM de las marcas de ", s$sector), paste0(M, " en el mapa: ", fmt_es(r$sov, 1), " hacia la derecha (SOV) y ", fmt_es(r$som, 1), " hacia arriba (SOM)."), w = 6.4, h = 5.6),
    .g_p("La diagonal divide el mapa en dos zonas."),
    .g_ul(c("<b>Por encima</b> (SOM &gt; SOV): <b>zona cosecha</b>. La marca vende m\u00e1s de lo que habla; vive de su base de clientes.", "<b>Por debajo</b> (SOV &gt; SOM): <b>zona inversi\u00f3n</b>. La marca habla m\u00e1s de lo que vende; invierte para crecer.")),
    .g_q(paste0("\u00bfQu\u00e9 distancia separa a ", M, " de la diagonal?"), .g_p("Exactamente su ESOV: ", fmt_es(abs(r$esov), 1), " puntos. Cuanto m\u00e1s lejos de la diagonal, mayor es el desajuste entre lo que habla y lo que vende."))))
  # 5
  tb <- z[order(-z$som), c("marca", "som", "sov", "esov")]
  tb <- .renombra(data.frame(a = tb$marca, b = fmt_es(tb$som, 1), c = fmt_es(tb$sov, 1), d = fmt_es(tb$esov, 1, TRUE), stringsAsFactors = FALSE),
                  c("Marca", "SOM (%)", "SOV (%)", "ESOV (pp)"))
  sS <- sum(z$som); sV <- sum(z$sov); encima <- sum(z$esov < 0)
  k <- min(3, floor(n / 2)); o <- order(-z$som)
  rr <- stats::cor(z$som, z$esov)
  cierre <- if (sS < 100.5 && sV < 100.5) paste0("<p>Las ", n, " marcas suman <b>", .pc(sS), "</b> de las ventas y <b>", .pc(sV), "</b> de la voz. Si las cuotas de la categor\u00eda suman 100 %, el resto de marcas (no incluidas) re\u00fane ",
                                                  .pc(100 - sS), " de las ventas y ", .pc(100 - sV), " de la voz: un ESOV de ", .pp(sS - sV), ". Los excesos negativos de unos se compensan con los positivos de otros.</p>") else ""
  pasos[[5]] <- list("\u00bfY las dem\u00e1s marcas? Aparece un patr\u00f3n", c(
    .g_p("Veamos las ", n, " marcas de la tabla."), .g_tbl(tb, hl = z$marca[o] == marca),
    .g_ul(c(paste0("<b>", encima, " de las ", n, " marcas</b> quedan por encima de la diagonal: hablan menos de lo que venden."),
            paste0("Las ", k, " mayores (", .lista_es(.html_esc(z$marca[o][seq_len(k)])), ") tienen un ESOV medio de ", .pp(mean(z$esov[o][seq_len(k)])), "; las ", k, " menores, de ", .pp(mean(z$esov[rev(o)][seq_len(k)])), "."))),
    cierre,
    .g_q("\u00bfEs casualidad?", .g_p("La correlaci\u00f3n entre SOM y ESOV es de <b>", fmt_es(rr, 2), "</b>. ", if (rr < -0.3) "Parece que no: esa regularidad es el punto de partida de la <b>curva AI</b>." else if (rr > 0.3) "El patr\u00f3n es el contrario del de la curva AI: las grandes hablan proporcionalmente m\u00e1s." else "No hay un patr\u00f3n lineal claro entre tama\u00f1o y exceso de voz.", " La gu\u00eda del sector lo cuantifica."))))
  # 6
  tam <- sort(unique(c(2, r$som, if (is.finite(-ja / jb) && -ja / jb > 0 && -ja / jb < 100) -ja / jb, 25)))
  tj <- .renombra(data.frame(a = vapply(tam, function(v) if (isTRUE(all.equal(v, r$som))) paste0(.pc(v), " (", marca, ")") else .pc(v), ""),
                   b = paste0(fmt_es(ja, 1), if (jb < 0) " \u2212 " else " + ", fmt_es(abs(jb), 2), " \u00d7 ", fmt_es(tam, 1)),
                   c = vapply(tam, function(v) .pp(ja + jb * v), ""), stringsAsFactors = FALSE),
                   c("Cuota de mercado (SOM)", "C\u00e1lculo", "ESOV habitual"))
  pasos[[6]] <- list("La referencia: \u00bfcu\u00e1nto habla una marca \u00abnormal\u00bb de su tama\u00f1o?", c(
    .g_p("El investigador John Philip Jones (1990) observ\u00f3, comparando m\u00e1s de mil marcas, que el exceso de voz habitual <b>depende del tama\u00f1o</b> de la marca (la <b>curva AI</b>). Una recta ajustada a su tabla (la <b>aproximaci\u00f3n lineal</b> que usa el paquete) es:"),
    .g_eq(paste0("ESOV de referencia = \u03b1 + \u03b2 \u00b7 SOM,  con \u03b1 = ", fmt_es(ja, 1, TRUE), " y \u03b2 = ", fmt_es(jb, 2))),
    .g_ul(c(paste0("<b>\u03b1 = ", fmt_es(ja, 1, TRUE), "</b>: una marca diminuta (SOM casi 0) suele hablar ", fmt_es(abs(ja), 1), " puntos ", if (ja > 0) "m\u00e1s" else "menos", " de lo que vende. Necesita hacer ruido para darse a conocer."),
            paste0("<b>\u03b2 = ", fmt_es(jb, 2), "</b>: por cada punto m\u00e1s de cuota, ese exceso ", if (jb < 0) "se reduce en " else "aumenta en ", fmt_es(abs(jb), 2), " puntos. Es la <b>econom\u00eda de escala</b>: a medida que una marca crece, necesita proporcionalmente menos voz."))),
    .g_p("Con estos dos n\u00fameros se calcula el exceso \u00abhabitual\u00bb para cualquier tama\u00f1o."), .g_tbl(tj, hl = abs(tam - r$som) < 1e-9),
    .g_warn(paste0("<b>\u00bfDe d\u00f3nde salen ", fmt_es(ja, 1), " y ", fmt_es(jb, 2), "?</b> Jones <b>no publica esa ecuaci\u00f3n</b>: los dos n\u00fameros son el resultado de ajustar una recta a su tabla de diferencias medias SOV \u2212 SOM por tramos de cuota, tal como figuran en la diapositiva docente de la que procede este material. ",
                   "<b>El paquete no ha contrastado estos valores con la publicaci\u00f3n original</b>: si los necesita para publicar, verif\u00edquelos.")),
    .g_warn("<b>Tres cautelas.</b> Primero, la curva original es c\u00f3ncava y la recta la aproxima. Segundo, son medias por tramos, no marcas individuales. Tercero, los datos de Jones son de bienes de gran consumo en mercados estables; por eso funcionan como <b>patr\u00f3n externo</b>, no como ley."),
    .g_warn("<b>Atenci\u00f3n a la direcci\u00f3n de la flecha.</b> La curva <i>describe</i> c\u00f3mo se comportan las marcas seg\u00fan su tama\u00f1o; muchas empresas, de hecho, fijan su presupuesto como un porcentaje de sus ventas. No demuestra que la cuota <i>cause</i> el gasto ni indica cu\u00e1nto <i>debe</i> invertir una marca. Es un punto de comparaci\u00f3n, no una orden.")))
  # 7
  pasos[[7]] <- list(paste0("Aplicar la referencia a ", M), c(
    .g_p("Si el exceso habitual de una marca de ", .pc(r$som), " es ", .pp(ja + jb * r$som), ", su <b>voz de referencia</b> es su cuota m\u00e1s ese exceso."),
    .g_eq(paste0("SOV de referencia = SOM + ESOV de referencia = ", fmt_es(r$som, 1), " ", if (ja + jb * r$som < 0) "\u2212 " else "+ ", fmt_es(abs(ja + jb * r$som), 1), " = ", fmt_es(sov_ref, 1), " %")),
    .g_p("Se compara con la voz real. La diferencia es la <b>brecha frente a la curva AI</b>."),
    .g_eq(paste0("Brecha = SOV real \u2212 SOV de referencia = ", fmt_es(r$sov, 1), " \u2212 ", fmt_es(sov_ref, 1), " = ", fmt_es(gap_j, 1), " pp")),
    fig(function() .fig_esov(z, NULL, marca, jones = x$jones, ref = TRUE), paste0("Referencia de Jones para ", marca), "L\u00ednea gris discontinua: ESOV habitual para cada cuota (curva AI de Jones). C\u00edrculo = ESOV de referencia de la marca; punto rojo = su ESOV real."),
    .g_p("Escrita en voz: <b>SOV<sub>ref</sub> = ", fmt_es(ja, 1), " + ", fmt_es(1 + jb, 2), " \u00d7 SOM</b>."),
    .g_q("\u00bfQu\u00e9 significa tener una brecha negativa?", .g_p("Que la marca habla menos de lo que suelen hablar las marcas de su tama\u00f1o. Con brecha positiva, m\u00e1s.")),
    .g_res(paste0("Respecto a la curva de Jones, la brecha de ", M, " es de <b>", .pp(gap_j), "</b>: ", if (gap_j < 0) "habla menos de lo habitual." else if (gap_j > 0) "habla m\u00e1s de lo habitual." else "habla lo habitual."))))
  # 8
  pasos[[8]] <- list("Una segunda referencia: la recta ajustada a estos mismos datos", c(
    .g_p("\u00bfY si, en lugar de apoyarnos en Jones, calculamos la recta con las ", n, " marcas de esta tabla? Se hace con una <b>regresi\u00f3n por m\u00ednimos cuadrados</b>."),
    .g_eq(paste0("ESOV estimado = ", fmt_es(a$alfa, 2, TRUE), if (a$beta < 0) " \u2212 " else " + ", fmt_es(abs(a$beta), 2), " \u00b7 SOM   \u21d4   SOV estimado = ", fmt_es(a$alfa, 2), " + ", fmt_es(1 + a$beta, 2), " \u00b7 SOM   (n = ", a$n, ", R\u00b2 = ", fmt_es(a$r2, 2), ")")),
    fig(function() .fig_esov(z, a, marca, jones = x$jones, ref = TRUE), paste0("Dos referencias para ", marca), "L\u00ednea gris discontinua: curva de Jones. L\u00ednea roja: recta ajustada a estas marcas. C\u00edrculo gris = referencia de Jones; c\u00edrculo negro = referencia de la recta."),
    .g_ul(c(paste0("La <b>pendiente</b> es ", if (abs(a$beta - jb) < 0.15) "parecida a la de Jones" else "distinta de la de Jones", " (", fmt_es(a$beta, 2), " frente a ", fmt_es(jb, 2), ")."),
            paste0("El <b>intercepto</b> es ", if (abs(a$alfa - ja) > 1.5) "muy distinto" else "similar", " (", fmt_es(a$alfa, 2), " frente a ", fmt_es(ja, 1), ")."),
            paste0("Con esta recta, la voz esperada de ", M, " es <b>", .pc(esp), "</b>; la real, ", .pc(r$sov), "."))),
    .g_res(paste0("Frente a la recta de su propia categor\u00eda, la brecha de ", M, " es de <b>", .pp(gap_s), "</b>: ", if (gap_s > 0) "habla algo m\u00e1s de lo esperado." else if (gap_s < 0) "habla algo menos de lo esperado." else "habla lo esperado.")),
    .g_q(paste0("Entonces, \u00bfhabla ", M, " de menos o de m\u00e1s?"),
         .g_p(if (sign(gap_j) != sign(gap_s)) paste0("Depende de la referencia. Frente a Jones, ", .pp(gap_j), "; frente a la recta de su categor\u00eda, ", .pp(gap_s), ". Ninguna es \u00abla verdad\u00bb: son puntos de comparaci\u00f3n.") else paste0("En este caso las dos referencias coinciden en el signo (", .pp(gap_j), " frente a Jones; ", .pp(gap_s), " frente a su categor\u00eda), aunque no en la magnitud. Siguen siendo puntos de comparaci\u00f3n, no una verdad.")))
    , .g_note(paste0("Cautela: la recta se apoya en ", a$n, " marcas; si son solo l\u00edderes, faltan las peque\u00f1as, que son las que definen el intercepto, de modo que este se estima con poca precisi\u00f3n. Por eso Danenberg et al. (2016) desaconsejan usar la curva de forma aislada."))))
  # 9
  dS <- epsilon * r$esov * anios; som_p <- r$som + dS
  pasos[[9]] <- list("El tiempo: \u00bfqu\u00e9 le ocurre a la cuota si no cambia nada?", c(
    .g_p("Aqu\u00ed entra una <b>hip\u00f3tesis</b>: hablar menos de lo que se vende erosiona la cuota poco a poco, y hablar m\u00e1s ayuda a ganarla. Se formula as\u00ed:"),
    .g_eq(paste0("\u0394SOM \u2248 \u03b5 \u00d7 ESOV \u00d7 a\u00f1os    con  \u03b5 = ", fmt_es(epsilon, 2))),
    .g_ul(c(paste0("<b>\u03b5 (elasticidad)</b> traduce el exceso de voz en cambio de cuota. Con ", fmt_es(epsilon, 2), ", cada +10 pp de ESOV equivalen a ", fmt_es(10 * epsilon, 2), " pp de cuota al a\u00f1o."), paste0("Con un horizonte de ", anios, " a\u00f1os (par\u00e1metro <code>anios</code>):"))),
    .g_eq(paste0("\u0394SOM \u2248 ", fmt_es(epsilon, 2), " \u00d7 (", fmt_es(r$esov, 1), ") \u00d7 ", anios, " \u2248 ", fmt_es(dS, 2), " pp")),
    .g_res(paste0("<b>SOM proyectado</b> = ", fmt_es(r$som, 1), " ", if (dS < 0) "\u2212" else "+", " ", fmt_es(abs(dS), 2), " \u2248 <b>", .pc(som_p, 2), "</b>: la cuota que tendr\u00eda ", M, " al cabo de ", anios, " a\u00f1os si mantuviera su inversi\u00f3n.")),
    .g_note("La elasticidad no se mide en estos datos: es un <b>supuesto operativo</b> (por defecto 0,05), no un resultado. Para una referencia emp\u00edrica, v\u00e9anse las elasticidades publicitarias medias de Sethuraman et al. (2011). Las cuotas se reajustan para que sigan sumando 100 %.")))
  # 10
  f <- 1 + inversion / 100; sov2 <- 100 * (r$sov / 100 * f) / (1 + (f - 1) * r$sov / 100)
  esov2 <- sov2 - r$som; dS2 <- epsilon * esov2 * anios; gap2 <- sov2 - sov_ref
  pasos[[10]] <- list(paste0("Mover la palanca: \u00bfy si ", M, " invierte un ", fmt_es(inversion, 0), " % ", if (inversion >= 0) "m\u00e1s" else "menos", "?"), c(
    .g_p("Es lo que simula el par\u00e1metro <code>inversion</code> (", fmt_es(inversion, 0), " %). Como el total de la categor\u00eda tambi\u00e9n cambia, el nuevo SOV es:"),
    .g_eq(paste0("SOV nuevo = SOV \u00d7 (1 + p) / (1 + p \u00d7 SOV),   con p = ", fmt_es(inversion / 100, 2), "   \u2192   ", fmt_es(sov2, 1), " %")),
    .g_ul(c(paste0("Su SOV pasa de ", .pc(r$sov), " a <b>", .pc(sov2), "</b> y su ESOV, de ", .pp(r$esov), " a <b>", .pp(esov2), "</b>."),
            paste0("Su SOM proyectado a ", anios, " a\u00f1os pasa de ", .pc(som_p, 2), " a <b>", .pc(r$som + dS2, 2), "</b> (", .pp(dS2 - dS, 2), " respecto a no cambiar)."),
            paste0("Frente a la curva de Jones, la brecha pasa de ", .pp(gap_j), " a <b>", .pp(gap2), "</b>."))),
    .g_q("\u00bfCompensa gastar m\u00e1s para ganar unas d\u00e9cimas de cuota?", .g_p("El modelo no lo dice: depende de cu\u00e1nto vale para la empresa cada punto de mercado. Lo que s\u00ed hace es ordenar la discusi\u00f3n con cifras."))))

  N <- length(pasos)
  intro <- c('<div class="sg-root">', .g_banner_sim(x),
    paste0('<p class="sg-intro">Esta gu\u00eda responde a <b>una sola pregunta</b>: \u00bfinvierte ', M, " en publicidad lo que cabr\u00eda esperar de una marca de su tama\u00f1o?</p>"),
    "<p>Para contestarla basta encadenar cinco ideas. Cada una se apoya en la anterior; por eso conviene leerlas en orden.</p>",
    .g_ul(c("<b>Lo que vende</b>: la cuota de mercado.", "<b>Lo que habla</b>: la cuota de voz.", "<b>Cu\u00e1nto habla de m\u00e1s o de menos</b>: el exceso de voz.",
            "<b>Lo que suelen hablar las marcas de su tama\u00f1o</b>: la curva de referencia.", "<b>Qu\u00e9 podr\u00eda ocurrir si cambia su inversi\u00f3n</b>: la proyecci\u00f3n.")),
    paste0('<p class="sg-note"><b>Datos.</b> Categor\u00eda: ', .html_esc(s$sector), " (", n, " marcas). La cuota de mercado y la de voz se expresan en porcentaje de la categor\u00eda.</p>"))
  cuerpo <- vapply(seq_along(pasos), function(i) .g_step(i, N, pasos[[i]][[1]], pasos[[i]][[2]]), "")
  resumen <- paste0('<section class="sg-s"><div class="sg-step">Resumen</div><h4 class="sg-h">La cadena de razonamiento completa</h4>',
    .g_ol(c(paste0("<b>Vender</b>: SOM = ", .pc(r$som), "."), paste0("<b>Hablar</b>: SOV = ", .pc(r$sov), "."), paste0("<b>Comparar</b>: ESOV = ", .pp(r$esov), "."),
            paste0("<b>Fijar una referencia</b>: Jones indica ", .pc(sov_ref), "; la recta de la categor\u00eda, ", .pc(esp), "."),
            paste0("<b>Medir la brecha</b>: ", .pp(gap_j), " frente a Jones; ", .pp(gap_s), " frente a su categor\u00eda."),
            paste0("<b>Proyectar</b>: con la hip\u00f3tesis de \u03b5 = ", fmt_es(epsilon, 2), ", SOM = ", .pc(som_p, 2), " a ", anios, " a\u00f1os."),
            "<b>Decidir</b>: la conclusi\u00f3n depende de la referencia elegida; el modelo ordena la discusi\u00f3n, no la zanja.")),
    '<div class="sg-warn"><b>Tres l\u00edmites que deben recordarse.</b>', .g_ul(c("Es un <b>corte transversal</b>: describe asociaciones, no prueba que invertir m\u00e1s <i>cause</i> ganar cuota.",
                                                                              "Con pocas marcas, la recta es orientativa; si solo figuran las l\u00edderes, el intercepto es poco fiable.",
                                                                              "La elasticidad es un <b>supuesto</b>, no un resultado de estos datos.")), "</div></section></div>")
  paste(c(intro, cuerpo, resumen), collapse = "\n")
}

# ------------------------------------------------------------------- público
#' Guías paso a paso para interpretar los datos
#'
#' Genera, con las cifras de los datos analizados, dos guías pensadas para
#' estudiantes: cada una responde a **una sola pregunta** y la contesta
#' encadenando pasos breves, con fórmulas, ejemplos, preguntas y resultados
#' destacados.
#'
#' * `tipo = "marca"`: ¿invierte esta marca lo que cabría esperar de una marca
#'   de su tamaño? Recorre SOM, SOV, ESOV, el mapa, la referencia de Jones, la
#'   recta de la categoría, la proyección y una simulación de cambio de
#'   inversión.
#' * `tipo = "sector"`: ¿podemos fiarnos de una recta calculada con pocas
#'   marcas? Recorre la recta de mínimos cuadrados, su incertidumbre, la
#'   comparación entre categorías, el análisis de sensibilidad (dejar una
#'   marca fuera), los diagnósticos de influencia, Theil-Sen y las formas
#'   funcionales.
#'
#' Los textos condicionales (por ejemplo, «cambia de signo») solo aparecen
#' cuando los datos los respaldan. Si los datos son sintéticos, la guía lo
#' indica en un recuadro. El valor de la elasticidad `epsilon` es un supuesto
#' operativo, no una estimación.
#'
#' @param x Objeto `sov_analisis` o datos admitidos por [sov_analiza()].
#' @param tipo `"sector"` (por defecto) o `"marca"`.
#' @param categoria Identificador (`caso`) o nombre de la categoría; por
#'   defecto, la primera con al menos 4 marcas.
#' @param marca Marca de referencia; por defecto, la de mayor cuota.
#' @param epsilon Elasticidad supuesta para la proyección (solo `"marca"`).
#' @param anios Horizonte de la proyección, en años (solo `"marca"`).
#' @param inversion Cambio porcentual de inversión a simular (solo `"marca"`).
#' @param formato `"html"` (por defecto, con figuras incrustadas) o `"texto"`.
#' @param archivo Ruta de un HTML autónomo para guardar la guía (opcional).
#' @return Cadena HTML (o texto) con la guía; si `archivo` no es `NULL`, la
#'   ruta del archivo, de forma invisible.
#' @examples
#' x <- sov_analiza(adage2019, B = 0)
#' cat(substr(sov_guia(x, "sector", "auto_marcas", formato = "texto"), 1, 600))
#' @export
sov_guia <- function(x, tipo = c("sector", "marca"), categoria = NULL, marca = NULL,
                     epsilon = 0.05, anios = 3, inversion = 50,
                     formato = c("html", "texto"), archivo = NULL) {
  tipo <- match.arg(tipo); formato <- match.arg(formato)
  x <- sov_analiza(x, B = 0)
  fig <- formato == "html"
  h <- if (tipo == "sector") .guia_sector(x, categoria, marca, fig)
       else .guia_marca(x, categoria, marca, epsilon, anios, inversion, fig)
  if (formato == "html") h <- paste0(.g_css(), h)
  if (!is.null(archivo)) {
    pag <- paste0('<!DOCTYPE html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">',
                  "<title>Gu\u00eda paso a paso \u00b7 mediaSOV</title>", '</head><body style="margin:16px auto;max-width:960px;padding:0 16px;font-family:system-ui,Segoe UI,Arial,sans-serif">',
                  h, "</body></html>")
    con <- file(archivo, "wb"); on.exit(close(con)); writeBin(charToRaw(enc2utf8(pag)), con)
    message("Gu\u00eda guardada en: ", normalizePath(archivo))
    return(invisible(archivo))
  }
  if (formato == "texto") return(.html_a_texto(h))
  h
}

.html_a_texto <- function(h) {
  h <- gsub("(?s)<figure.*?</figure>", "", h, perl = TRUE)
  h <- gsub("(?s)<style>.*?</style>", "", h, perl = TRUE)
  h <- gsub("<li>", "\n- ", h, fixed = TRUE)
  h <- gsub("<tr>|<tr class=\"hl\">", "\n", h)
  h <- gsub("</t[dh]>", " | ", h)
  h <- gsub("<div class=\"sg-step\">", "\n\n=== ", h, fixed = TRUE)
  h <- gsub("</h4>|</p>|</div>|</ul>|</ol>|</section>|</pre>", "\n", h)
  h <- gsub("<[^>]+>", "", h)
  h <- gsub("&lt;", "<", h, fixed = TRUE); h <- gsub("&gt;", ">", h, fixed = TRUE); h <- gsub("&quot;", "\"", h, fixed = TRUE); h <- gsub("&#39;", "'", h, fixed = TRUE); h <- gsub("&amp;", "&", h, fixed = TRUE)
  h <- gsub("\n{3,}", "\n\n", h)
  trimws(h)
}
