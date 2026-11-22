# Plan de cuota de voz a varios años ------------------------------------------

#' Plan de cuota de voz: cuánto SOV presupuestar y cómo repartirlo en el tiempo
#'
#' Calcula la senda de cuota de voz (SOV) que lleva una marca desde su cuota de
#' mercado actual hasta una cuota objetivo al cierre del horizonte, el
#' presupuesto de cada periodo y la cuota de mercado prevista. Es la versión
#' operativa del método Peckham 1,5 ampliado (apartado 13 del README).
#'
#' **Modelo.** La cuota de mercado \eqn{s} persigue a la voz según
#' \deqn{ds/dt = k\,[v(t - L) - v^\ast(s)], \qquad v^\ast(s) = \alpha + (1+\beta)\,s,}
#' donde \eqn{v^\ast(s)} es la SOV de mantenimiento (la voz con la que una
#' marca de cuota \eqn{s} ni gana ni pierde), \eqn{k} la velocidad de respuesta
#' y \eqn{L} el retardo con que la voz se traslada a la cuota. La voz es
#' constante dentro de cada periodo, de modo que la trayectoria se calcula de
#' forma exacta periodo a periodo.
#'
#' **Sendas.** Con `senda = "constante"` la SOV es la misma en todos los
#' periodos que influyen en la cuota final; sin retardo y con un único periodo
#' por año coincide con la fórmula cerrada del apartado 13.3. Con
#' `senda = "minimo_coste"` se elige la SOV de cada periodo que alcanza el
#' objetivo con el menor presupuesto total, sin bajar de `sov_minima`. La voz
#' de los últimos periodos se ha erosionado menos al llegar el cierre, de modo
#' que rinde más por punto; como el presupuesto, \eqn{A = X\,v/(100-v)}, crece
#' más que proporcionalmente con la SOV, la solución no lo concentra todo en el
#' último periodo, sino que mantiene la voz mínima al principio y la eleva de
#' forma escalonada hacia el final. La carga hacia el final es tanto más
#' marcada cuanto mayor es \eqn{k(1+\beta)}; con respuestas lentas, la senda de
#' mínimo coste apenas se separa de la constante. La condición de óptimo es
#' \eqn{100 - v_j = \kappa\sqrt{X_j/g_j}}, acotada por `sov_minima`, donde
#' \eqn{g_j} es el efecto de la voz del periodo \eqn{j} sobre la cuota final.
#'
#' **Retardo.** Con `retardo > 0`, la cuota responde durante los primeros
#' \eqn{L} años a la voz actual (`sov`), y la voz de los últimos \eqn{L} años
#' del horizonte solo actúa después del cierre. Esos periodos se fijan en la
#' SOV de mantenimiento del objetivo, que es la que conserva la cuota alcanzada.
#' Schroer (1990) sitúa la aparición de la relación entre gasto y cuota hacia
#' los 18 meses (`retardo = 1.5`).
#'
#' **Presupuesto.** Si la marca invierte hoy `inversion` con una SOV `sov`, la
#' inversión de la competencia es \eqn{X = \mathrm{inversion}\,(100 -
#' \mathrm{sov})/\mathrm{sov}}, y se supone constante salvo que se indique
#' `inversion_competencia`. Con `inversion = 100` (valor por defecto), el
#' presupuesto anual se expresa como índice con la inversión actual igual a 100.
#'
#' @param som Cuota de mercado actual de la marca, en %.
#' @param sov Cuota de voz actual de la marca, en %.
#' @param objetivo Cuota de mercado que se quiere alcanzar al cierre del
#'   horizonte, en %.
#' @param anios Horizonte del plan, en años.
#' @param k Velocidad de respuesta: puntos de cuota ganados al año por cada
#'   punto de voz por encima del mantenimiento. El apartado 13.4 del README
#'   ofrece dos anclajes: 0,05 (marca madura de gran consumo) y 0,55 (velocidad
#'   implícita en la regla de Peckham). Puede estimarse con [sov_efecto_esov()].
#' @param referencia `"paridad"` (mantenimiento en SOV = SOM) o `"jones"`
#'   (recta de Jones, α = 6,4 y β = −0,38). Se ignora si se indican `alfa` y
#'   `beta`.
#' @param alfa,beta Intercepto y pendiente de la recta ESOV = α + β·SOM propia
#'   de la categoría, por ejemplo los estimados con [sov_analiza()]. Se exige
#'   \eqn{1 + \beta > 0}.
#' @param periodos Número de periodos por año: 1 (anual), 2 (semestral), 4
#'   (trimestral) o 12 (mensual).
#' @param senda `"constante"` o `"minimo_coste"`.
#' @param sov_minima SOV por debajo de la cual no baja la senda de mínimo
#'   coste. Por defecto, la SOV de mantenimiento de la cuota actual, es decir,
#'   la voz que conserva la cuota de partida.
#' @param retardo Retardo de la respuesta de la cuota a la voz, en años. Se
#'   redondea al periodo más próximo y debe ser menor que `anios`.
#' @param inversion Inversión publicitaria anual actual de la marca. Por
#'   defecto, 100.
#' @param inversion_competencia Inversión anual del resto de la categoría. Un
#'   número (constante) o un vector con un valor por periodo, expresado en
#'   ritmo anual. Si es `NULL`, se deduce de `inversion` y `sov`.
#' @return Objeto `sov_plan`, una lista con `periodos` (`data.frame` con una
#'   fila por periodo: SOV, ESOV, presupuesto y cuota de mercado al inicio y al
#'   cierre), `resumen` (lista con la SOV media, el presupuesto total, el índice
#'   frente a mantener la inversión actual, la SOV de mantenimiento a partir del
#'   cierre y la cuota final) y `parametros`.
#' @seealso [sov_mapa()], [sov_grafico()], [sov_efecto_esov()].
#' @references
#' Jones, J. P. (1990). Ad spending: Maintaining market share. *Harvard
#' Business Review, 68*(1), 38–42.
#'
#' Peckham, J. O. (1981). *The wheel of marketing*. Nielsen Marketing Research.
#'
#' Schroer, J. C. (1990). Ad spending: Growing market share. *Harvard Business
#' Review, 68*(1), 44–48.
#' @examples
#' # Marca E: del 8 % al 10 % de cuota en dos años, con la referencia de paridad
#' sov_plan(som = 8, sov = 9, objetivo = 10)
#'
#' # Reparto trimestral de mínimo coste con la recta de Jones
#' p <- sov_plan(8, 9, 10, referencia = "jones", periodos = 4,
#'               senda = "minimo_coste")
#' p$periodos
#' plot(p)
#'
#' # Con un retardo de seis meses
#' sov_plan(8, 9, 10, periodos = 4, retardo = 0.5)
#' @export
sov_plan <- function(som, sov, objetivo, anios = 2, k = 0.55,
                     referencia = c("paridad", "jones"), alfa = NULL, beta = NULL,
                     periodos = 1, senda = c("constante", "minimo_coste"),
                     sov_minima = NULL, retardo = 0, inversion = 100, inversion_competencia = NULL) {
  referencia <- match.arg(referencia)
  senda <- match.arg(senda)
  .num1 <- function(x, nombre) {
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
      stop("`", nombre, "` debe ser un \u00fanico n\u00famero.", call. = FALSE)
    }
  }
  for (n in c("som", "sov", "objetivo", "anios", "k", "periodos", "retardo", "inversion")) {
    .num1(get(n), n)
  }
  if (som <= 0 || som >= 100 || objetivo <= 0 || objetivo >= 100) {
    stop("`som` y `objetivo` deben estar entre 0 y 100.", call. = FALSE)
  }
  if (sov <= 0 || sov >= 100) stop("`sov` debe estar entre 0 y 100.", call. = FALSE)
  if (anios <= 0) stop("`anios` debe ser positivo.", call. = FALSE)
  if (k <= 0) stop("`k` debe ser positivo.", call. = FALSE)
  if (inversion <= 0) stop("`inversion` debe ser positiva.", call. = FALSE)
  if (periodos < 1 || periodos != round(periodos)) {
    stop("`periodos` debe ser un entero positivo (1, 2, 4 o 12).", call. = FALSE)
  }
  m <- anios * periodos
  if (abs(m - round(m)) > 1e-8) {
    stop("`anios * periodos` debe ser un n\u00famero entero de periodos.", call. = FALSE)
  }
  m <- as.integer(round(m))
  h <- 1 / periodos

  # Recta de mantenimiento.
  if (is.null(alfa) != is.null(beta)) {
    stop("Indique `alfa` y `beta` a la vez, o ninguno de los dos.", call. = FALSE)
  }
  if (!is.null(alfa)) {
    .num1(alfa, "alfa"); .num1(beta, "beta")
    origen <- "Recta indicada por el usuario"
  } else if (referencia == "jones") {
    alfa <- .jones_slide[["alfa"]]; beta <- .jones_slide[["beta"]]
    origen <- "Recta de Jones (1990, p. 40)"
  } else {
    alfa <- 0; beta <- 0
    origen <- "Paridad (SOV = SOM)"
  }
  if (1 + beta <= 0) stop("La recta exige 1 + beta > 0.", call. = FALSE)
  mant <- function(s) alfa + (1 + beta) * s

  # Retardo en periodos.
  if (retardo < 0) stop("`retardo` no puede ser negativo.", call. = FALSE)
  l <- as.integer(round(retardo * periodos))
  if (abs(retardo * periodos - l) > 1e-8) {
    warning("El retardo se ha redondeado a ", fmt_es(l / periodos, 2),
            " a\u00f1os para ajustarlo a la duraci\u00f3n de los periodos.", call. = FALSE)
  }
  if (l >= m) {
    stop("El retardo debe ser menor que el horizonte: con un retardo de ",
         fmt_es(l / periodos, 2), " a\u00f1os, la voz del plan no llega a la cuota antes del cierre.",
         call. = FALSE)
  }

  # Inversión de la competencia, en ritmo anual, por periodo.
  if (is.null(inversion_competencia)) {
    X <- rep(inversion * (100 - sov) / sov, m)
  } else {
    X <- inversion_competencia
    if (!is.numeric(X) || any(!is.finite(X)) || any(X <= 0) || !length(X) %in% c(1L, m)) {
      stop("`inversion_competencia` debe ser un n\u00famero positivo o un vector de ", m,
           " valores positivos (uno por periodo).", call. = FALSE)
    }
    X <- rep_len(X, m)
  }

  # Dinámica exacta con voz constante en cada periodo.
  c0 <- k * (1 + beta)
  dec <- exp(-c0 * h)
  paso <- function(s, v) s * dec + (1 - dec) * (v - alfa) / (1 + beta)
  ef <- seq_len(m - l)              # periodos cuya voz act\u00faa antes del cierre
  # Cuota al cierre como función lineal de la voz efectiva: s_T = a0 + sum(g * v).
  a0 <- som * dec^m + sum((1 - dec) * (sov - alfa) / (1 + beta) * dec^(m - seq_len(l)))
  a0 <- a0 - sum((1 - dec) * alfa / (1 + beta) * dec^(m - l - ef))
  g <- (1 - dec) / (1 + beta) * dec^(m - l - ef)
  R <- objetivo - a0

  if (senda == "constante") {
    v_ef <- rep(R / sum(g), length(ef))
  } else {
    # Condici\u00f3n de primer orden: 100 X_j / (100 - v_j)^2 = lambda g_j,
    # con la cota inferior sov_minima (soluci\u00f3n por nivelaci\u00f3n).
    lo <- sov_minima %||% max(0, mant(som))
    .num1(lo, "sov_minima")
    if (lo < 0 || lo >= 100) stop("`sov_minima` debe estar entre 0 y 100.", call. = FALSE)
    if (sum(g) * lo >= R) {
      stop("Con una SOV de ", fmt_es(lo, 1), " % en todos los periodos la cuota ya supera el objetivo: ",
           "rebaje `sov_minima` o use la senda constante.", call. = FALSE)
    }
    hi <- 100 - 1e-9
    if (sum(g) * hi <= R) {
      stop("El objetivo exige una cuota de voz igual o superior al 100 %: ",
           "ampl\u00ede el horizonte o revise el objetivo.", call. = FALSE)
    }
    q <- sqrt(X[ef] / g)
    senda_k <- function(kap) pmin(hi, pmax(lo, 100 - kap * q))
    kap <- stats::uniroot(function(kap) sum(g * senda_k(kap)) - R,
                          c(0, (100 - lo) / min(q)), tol = 1e-13)$root
    v_ef <- senda_k(kap)
  }
  if (any(v_ef >= 100)) {
    stop("El objetivo exige una cuota de voz igual o superior al 100 %: ",
         "ampl\u00ede el horizonte o revise el objetivo.", call. = FALSE)
  }
  if (any(v_ef < 0)) {
    stop("La senda resultante exige una cuota de voz negativa en alg\u00fan periodo: ",
         "el objetivo se alcanzar\u00eda sin invertir. Revise el objetivo o el horizonte.",
         call. = FALSE)
  }
  v <- c(v_ef, rep(mant(objetivo), l))

  # Trayectoria de la cuota (la voz actúa con l periodos de retardo).
  v_actua <- c(rep(sov, l), v_ef)
  s_ini <- numeric(m); s_fin <- numeric(m)
  s <- som
  for (j in seq_len(m)) {
    s_ini[j] <- s
    s <- paso(s, v_actua[j])
    s_fin[j] <- s
  }

  pres <- X * h * v / (100 - v)
  anio <- (seq_len(m) - 1L) %/% periodos + 1L
  sub <- (seq_len(m) - 1L) %% periodos + 1L
  etiqueta <- switch(as.character(periodos),
    "1" = paste("A\u00f1o", anio),
    "2" = paste0("A\u00f1o ", anio, ", S", sub),
    "4" = paste0("A\u00f1o ", anio, ", T", sub),
    "12" = paste0("A\u00f1o ", anio, ", M", sub),
    paste0("A\u00f1o ", anio, ", P", sub))
  tab <- data.frame(
    periodo = etiqueta, inicio = (seq_len(m) - 1L) * h, fin = seq_len(m) * h,
    sov = v, esov = v - s_ini, presupuesto = pres,
    som_inicio = s_ini, som_fin = s_fin,
    actua_antes_del_cierre = seq_len(m) %in% ef,
    stringsAsFactors = FALSE
  )
  base <- sum(X * h * sov / (100 - sov))
  res <- list(
    sov_media = sum(v * h) / anios,
    sov_min = min(v), sov_max = max(v),
    presupuesto_total = sum(pres),
    presupuesto_anual = tapply(pres, anio, sum),
    indice = 100 * sum(pres) / base,
    sov_mantenimiento = mant(objetivo),
    som_final = s_fin[m],
    semivida = log(2) / c0
  )
  par <- list(som = som, sov = sov, objetivo = objetivo, anios = anios, k = k,
              alfa = alfa, beta = beta, referencia = origen, periodos = periodos,
              senda = senda, retardo = l / periodos, inversion = inversion,
              inversion_competencia = X)
  structure(list(periodos = tab, resumen = res, parametros = par), class = "sov_plan")
}

#' @rdname sov_plan
#' @param x Objeto `sov_plan`.
#' @param ... No se usa.
#' @export
print.sov_plan <- function(x, ...) {
  p <- x$parametros; r <- x$resumen; t <- x$periodos
  unidad <- c("1" = "anual", "2" = "semestral", "4" = "trimestral", "12" = "mensual")
  u <- unidad[as.character(p$periodos)]
  if (is.na(u)) u <- paste(p$periodos, "periodos por a\u00f1o")
  cat("Plan de cuota de voz: del ", fmt_es(p$som, 1), " % al ", fmt_es(p$objetivo, 1),
      " % de cuota en ", fmt_es(p$anios, 1), " a\u00f1os\n", sep = "")
  cat("  Mantenimiento: ", p$referencia, "; k = ", fmt_es(p$k, 2),
      " (semivida ", fmt_es(r$semivida, 1), " a\u00f1os)", sep = "")
  if (p$retardo > 0) cat("; retardo ", fmt_es(p$retardo, 2), " a\u00f1os", sep = "")
  cat("\n  Senda ", if (p$senda == "constante") "constante" else "de m\u00ednimo coste",
      ", reparto ", u, "\n\n", sep = "")
  d <- data.frame(
    Periodo = t$periodo, SOV = paste(fmt_es(t$sov, 1), "%"),
    ESOV = fmt_es(t$esov, 1, signo = TRUE),
    Presupuesto = fmt_es(t$presupuesto, 1),
    `SOM al cierre` = paste(fmt_es(t$som_fin, 2), "%"),
    check.names = FALSE
  )
  print(d, row.names = FALSE, right = TRUE)
  cat("\n  Presupuesto total: ", fmt_es(r$presupuesto_total, 1),
      " (", fmt_es(r$indice, 0), " frente a 100 si se mantiene la inversi\u00f3n actual)\n", sep = "")
  cat("  SOV de mantenimiento desde el cierre: ", fmt_es(r$sov_mantenimiento, 1), " %\n", sep = "")
  if (p$retardo > 0) {
    cat("  Los periodos del \u00faltimo tramo, de ", fmt_es(p$retardo, 2),
        " a\u00f1os, se fijan en esa SOV: su voz act\u00faa despu\u00e9s del cierre.\n", sep = "")
  }
  invisible(x)
}

#' @rdname sov_plan
#' @export
plot.sov_plan <- function(x, ...) {
  t <- x$periodos; p <- x$parametros
  op <- graphics::par(mar = c(8.4, 4.2, 2.6, 1.2), las = 1)
  on.exit(graphics::par(op))
  rango <- range(c(t$sov, t$som_inicio, t$som_fin, p$sov, x$resumen$sov_mantenimiento))
  rango <- rango + c(-1, 1) * 0.1 * diff(rango) + c(-0.5, 1)
  graphics::plot(NA, xlim = c(0, p$anios), ylim = rango, xlab = "A\u00f1os",
                 ylab = "Cuota (%)", main = "Senda de SOV y trayectoria de la SOM",
                 font.main = 1, cex.main = 1, axes = FALSE)
  marcas_x <- seq(0, p$anios, by = if (p$anios <= 3) 0.5 else 1)
  graphics::axis(1, at = marcas_x, labels = fmt_es(marcas_x, if (p$anios <= 3) 1 else 0))
  marcas_y <- pretty(rango)
  graphics::axis(2, at = marcas_y, labels = fmt_es(marcas_y, 0))
  graphics::box(col = "grey60")
  graphics::abline(h = marcas_y, col = "grey92")
  graphics::abline(v = seq_len(floor(p$anios - 1e-9)), col = "grey85", lty = 3)
  if (p$retardo > 0) {
    graphics::rect(p$anios - p$retardo, rango[1] - 10, p$anios, rango[2] + 10,
                   col = "#F1F1F1", border = NA)
  }
  graphics::abline(h = p$objetivo, lty = 2, col = "#A23B2A")
  graphics::abline(h = x$resumen$sov_mantenimiento, lty = 3, col = "grey35")
  graphics::segments(t$inicio, t$sov, t$fin, t$sov, lwd = 3, col = "#5B87B5")
  graphics::segments(t$fin[-nrow(t)], t$sov[-nrow(t)], t$inicio[-1], t$sov[-1],
                     lwd = 1, col = "#5B87B5")
  graphics::lines(c(t$inicio[1], t$fin), c(t$som_inicio[1], t$som_fin),
                  lwd = 2.4, col = "#1F3B5C")
  graphics::points(0, p$sov, pch = 19, cex = 0.9)
  ley <- c("SOV del plan", "SOM prevista", "SOM objetivo",
           "SOV de mantenimiento desde el cierre", "SOV actual")
  col <- c("#5B87B5", "#1F3B5C", "#A23B2A", "grey35", "black")
  lty <- c(1, 1, 2, 3, NA); lwd <- c(3, 2.4, 1, 1, NA); pch <- c(NA, NA, NA, NA, 19)
  if (p$retardo > 0) {
    ley <- c(ley, "Voz que act\u00faa despu\u00e9s del cierre")
    col <- c(col, "#F1F1F1"); lty <- c(lty, NA); lwd <- c(lwd, NA); pch <- c(pch, 15)
  }
  graphics::legend("bottom", inset = c(0, -0.6), xpd = TRUE, ncol = 2, bty = "n",
                   cex = 0.78, legend = ley, col = col, lty = lty, lwd = lwd, pch = pch,
                   pt.cex = c(rep(1, 5), 2)[seq_along(ley)], x.intersp = 0.8)
  invisible(x)
}
