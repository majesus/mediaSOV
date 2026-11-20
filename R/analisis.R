#' Pendiente e intercepto de Theil-Sen
#'
#' Estimador robusto de la recta: la pendiente es la mediana de las pendientes
#' entre todos los pares de puntos (Theil, 1950; Sen, 1968) y el intercepto es
#' la mediana de `y - pendiente * x`. Resiste a observaciones atípicas que
#' desplazan la recta de mínimos cuadrados.
#'
#' @param x,y Vectores numéricos de la misma longitud.
#' @return Vector con nombres `alfa` y `beta`.
#' @examples
#' sov_theil_sen(c(1, 2, 3, 4, 50), c(2, 4, 6, 8, 0))
#' @export
sov_theil_sen <- function(x, y) {
  n <- length(x)
  if (n < 2L) return(c(alfa = NA_real_, beta = NA_real_))
  p <- utils::combn(n, 2)
  dx <- x[p[2, ]] - x[p[1, ]]
  ok <- dx != 0
  if (!any(ok)) return(c(alfa = NA_real_, beta = NA_real_))
  b <- stats::median((y[p[2, ]][ok] - y[p[1, ]][ok]) / dx[ok])
  c(alfa = stats::median(y - b * x), beta = b)
}

# Errores tipicos robustos a heterocedasticidad HC3 (Long y Ervin, 2000) con
# intervalos t de n - 2 grados de libertad. Devuelve NA si alguna palanca es 1.
.hc3 <- function(m, nivel) {
  X <- stats::model.matrix(m); e <- stats::resid(m); h <- stats::hatvalues(m)
  if (any(h > 1 - 1e-8)) return(list(se = c(NA_real_, NA_real_), ic = matrix(NA_real_, 2, 2), p = c(NA_real_, NA_real_)))
  XtXi <- solve(crossprod(X))
  V <- XtXi %*% crossprod(X * (e / (1 - h))) %*% XtXi
  se <- sqrt(diag(V)); b <- stats::coef(m)
  q <- stats::qt(1 - (1 - nivel) / 2, m$df.residual)
  list(se = unname(se), ic = cbind(unname(b - q * se), unname(b + q * se)),
       p = unname(2 * stats::pt(-abs(b / se), m$df.residual)))
}

# Coeficientes MCO al omitir, de uno en uno, cada observación.
.sov_loo <- function(x, y) {
  n <- length(x)
  r <- t(vapply(seq_len(n), function(i) {
    xi <- x[-i]; yi <- y[-i]
    if (length(xi) < 2L || stats::var(xi) == 0) return(c(NA_real_, NA_real_))
    unname(stats::coef(stats::lm(yi ~ xi)))
  }, numeric(2)))
  data.frame(alfa = r[, 1], beta = r[, 2])
}

#' Ajuste ESOV = alfa + beta * SOM de una categoría
#'
#' Ajusta por mínimos cuadrados la recta del exceso de cuota de voz sobre la
#' cuota de mercado y la acompaña de medidas de robustez: errores típicos HC3
#' (robustos a heterocedasticidad, que en cuotas crece con la cuota de la
#' marca), estimador de Theil-Sen y rango de la pendiente al omitir cada marca
#' por turno.
#'
#' @param x Cuotas de mercado (SOM, %).
#' @param y Exceso de cuota de voz (ESOV = SOV - SOM, puntos porcentuales).
#' @param nivel Nivel de confianza de los intervalos (por defecto 0,95).
#' @return `NULL` si hay menos de 4 marcas o la cuota no varía; en otro caso,
#'   una lista con `n`, `alfa`, `beta`, errores típicos, intervalos (`ic_alfa`,
#'   `ic_beta`), `p_alfa`, `p_beta`, la alternativa robusta a heterocedasticidad
#'   HC3 (`se_beta_hc3`, `ic_beta_hc3`, `p_beta_hc3`; Long y Ervin, 2000), `r2`,
#'   `sigma`, `ts_alfa`, `ts_beta`,
#'   `loo` (coeficientes al omitir cada marca), `loo_rango`, `som_umbral`
#'   (cuota en la que el ESOV medio se anula, si alfa > 0, beta < 0 y beta es
#'   significativa) y `modelo` (objeto `lm`).
#' @examples
#' d <- sov_prepara(adage2019)
#' z <- d[d$caso == "auto_marcas", ]
#' a <- sov_ajusta(z$som, z$esov)
#' a$beta; a$ic_beta
#' @export
sov_ajusta <- function(x, y, nivel = 0.95) {
  ok <- is.finite(x) & is.finite(y)
  x <- x[ok]; y <- y[ok]
  n <- length(x)
  if (n < 4L || stats::var(x) == 0) return(NULL)
  m <- stats::lm(y ~ x)
  sm <- summary(m)
  cf <- sm$coefficients
  ci <- stats::confint(m, level = nivel)
  a <- unname(cf[1, 1]); b <- unname(cf[2, 1]); pb <- unname(cf[2, 4])
  ts <- sov_theil_sen(x, y)
  loo <- .sov_loo(x, y)
  rb <- .hc3(m, nivel)
  list(
    n = n, gl = m$df.residual,
    alfa = a, beta = b,
    se_alfa = unname(cf[1, 2]), se_beta = unname(cf[2, 2]),
    ic_alfa = unname(ci[1, ]), ic_beta = unname(ci[2, ]),
    p_alfa = unname(cf[1, 4]), p_beta = pb,
    se_beta_hc3 = rb$se[2], ic_beta_hc3 = rb$ic[2, ], p_beta_hc3 = rb$p[2],
    r2 = sm$r.squared, sigma = sm$sigma,
    ts_beta = unname(ts["beta"]), ts_alfa = unname(ts["alfa"]),
    loo = loo, loo_rango = range(loo$beta, na.rm = TRUE),
    som_umbral = if (a > 0 && b < 0 && pb < 0.05) -a / b else NA_real_,
    modelo = m
  )
}

#' Diagnóstico de influencia por marca
#'
#' Para cada marca calcula la palanca (*hat*), el residuo estudentizado
#' externo (*t**), la distancia de Cook, el DFBETAS de la pendiente y la
#' pendiente que resultaría sin esa marca. Marca alertas con las reglas
#' habituales (Belsley, Kuh y Welsch, 1980; Cook, 1977):
#' \describe{
#'   \item{P (palanca)}{palanca > 4/n: la marca tiene una cuota inusual.}
#'   \item{A (atípico)}{|t*| > 2: el ESOV de la marca se aparta de la recta.}
#'   \item{I (influyente)}{distancia de Cook > 4/n o |DFBETAS| > 2/raíz(n):
#'     omitir la marca cambia de forma apreciable la pendiente.}
#' }
#' Son umbrales heurísticos, no contrastes de hipótesis.
#'
#' @param x,y Cuota de mercado (SOM) y ESOV.
#' @param marca Nombres de las marcas.
#' @param sov Cuota de voz (opcional; solo se devuelve en la tabla).
#' @return `data.frame` con una fila por marca y el atributo `umbrales`.
#' @examples
#' d <- sov_prepara(adage2019)
#' z <- d[d$caso == "restaurantes", ]
#' sov_influencia(z$som, z$esov, z$marca, z$sov)
#' @export
sov_influencia <- function(x, y, marca = seq_along(x), sov = NA_real_) {
  n <- length(x)
  m <- stats::lm(y ~ x)
  h <- unname(stats::hatvalues(m))
  e <- unname(stats::resid(m))
  ts <- unname(stats::rstudent(m))
  D <- unname(stats::cooks.distance(m))
  dfb <- unname(stats::dfbetas(m)[, 2])
  loo <- .sov_loo(x, y)
  out <- data.frame(
    marca = as.character(marca), som = x, sov = sov, esov = y,
    residuo = e, palanca = h, t_stud = ts, cook = D, dfbetas = dfb,
    beta_sin = loo$beta, alfa_sin = loo$alfa,
    stringsAsFactors = FALSE
  )
  out$alerta_P <- !is.na(h) & h > 4 / n
  out$alerta_A <- !is.na(ts) & abs(ts) > 2
  out$alerta_I <- (!is.na(D) & D > 4 / n) | (!is.na(dfb) & abs(dfb) > 2 / sqrt(n))
  out$alerta <- vapply(seq_len(n), function(i) {
    paste0(c(if (out$alerta_P[i]) "P", if (out$alerta_A[i]) "A", if (out$alerta_I[i]) "I"),
           collapse = " ")
  }, character(1))
  attr(out, "umbrales") <- c(palanca = 4 / n, cook = 4 / n, dfbetas = 2 / sqrt(n), t_stud = 2)
  out
}

#' Bootstrap de pares para la pendiente
#'
#' Remuestrea con reemplazo las marcas (pares SOM-ESOV) y devuelve el intervalo
#' percentil de la pendiente por mínimos cuadrados y por Theil-Sen, así como la
#' proporción de remuestras con pendiente negativa. No supone normalidad de
#' los errores, pero con pocas marcas es solo orientativo.
#'
#' @param x,y Cuota de mercado y ESOV.
#' @param B Número de remuestras. Con `B = 0` no se calcula nada y se devuelve
#'   `NULL`.
#' @param nivel Nivel de confianza.
#' @param semilla Semilla (el estado del generador del usuario se restaura al
#'   terminar).
#' @param theil_sen Si `FALSE`, no se calcula el intervalo de Theil-Sen (más
#'   rápido).
#' @return Lista con `B_validas`, `ols`, `ts` (intervalos) y `p_neg`, o `NULL`.
#' @examples
#' d <- sov_prepara(adage2019)
#' z <- d[d$caso == "auto_marcas", ]
#' sov_bootstrap(z$som, z$esov, B = 300)
#' @export
sov_bootstrap <- function(x, y, B = 2000, nivel = 0.95, semilla = 2019, theil_sen = TRUE) {
  if (is.null(B) || B < 1) return(NULL)
  n <- length(x)
  r <- .con_semilla(semilla, vapply(seq_len(B), function(i) {
    k <- sample.int(n, n, replace = TRUE)
    xs <- x[k]; ys <- y[k]
    if (stats::var(xs) == 0) return(c(NA_real_, NA_real_))
    c(stats::cov(xs, ys) / stats::var(xs),
      if (theil_sen) unname(sov_theil_sen(xs, ys)["beta"]) else NA_real_)
  }, numeric(2)))
  q <- c((1 - nivel) / 2, 1 - (1 - nivel) / 2)
  list(
    B_validas = sum(is.finite(r[1, ])),
    ols = stats::quantile(r[1, ], q, na.rm = TRUE, names = FALSE),
    ts = if (theil_sen) stats::quantile(r[2, ], q, na.rm = TRUE, names = FALSE) else c(NA_real_, NA_real_),
    p_neg = mean(r[1, ] < 0, na.rm = TRUE)
  )
}

#' Compara formas funcionales: lineal, logarítmica y cuadrática
#'
#' Ajusta ESOV = f(SOM) con tres formas (lineal, `ln SOM` y cuadrática) y las
#' compara por validación cruzada «dejando una fuera» (RMSE, calculado con los
#' residuos PRESS) y por el criterio de Akaike corregido para muestras pequeñas
#' (AICc = AIC + 2k(k+1)/(n-k-1), con k los parámetros incluida la varianza;
#' Hurvich y Tsai, 1989). Menor es mejor en ambos criterios. Con pocas marcas,
#' la forma cuadrática tiende a sobreajustar.
#'
#' @param x,y Cuota de mercado y ESOV.
#' @return `data.frame` con `forma`, `k`, `rmse_cv`, `aicc`, `delta_aicc`
#'   (respecto a la lineal), `mejor_rmse` y `mejor_aicc`.
#' @examples
#' d <- sov_prepara(adage2019)
#' z <- d[d$caso == "auto_marcas", ]
#' sov_formas(z$som, z$esov)
#' @export
sov_formas <- function(x, y) {
  n <- length(x)
  ajustes <- list(
    "Lineal" = tryCatch(stats::lm(y ~ x), error = function(e) NULL),
    "ln SOM" = if (all(x > 0)) stats::lm(y ~ log(x)) else NULL,
    "Cuadr\u00e1tica" = tryCatch(stats::lm(y ~ x + I(x^2)), error = function(e) NULL)
  )
  res <- do.call(rbind, lapply(names(ajustes), function(nm) {
    m <- ajustes[[nm]]
    if (is.null(m)) {
      return(data.frame(forma = nm, k = NA_real_, rmse_cv = NA_real_, aicc = NA_real_))
    }
    h <- stats::hatvalues(m); e <- stats::resid(m)
    k <- attr(stats::logLik(m), "df")
    rmse <- if (any(h > 1 - 1e-8)) NA_real_ else sqrt(mean((e / (1 - h))^2))
    aicc <- if (n - k - 1 > 0) stats::AIC(m) + 2 * k * (k + 1) / (n - k - 1) else NA_real_
    data.frame(forma = nm, k = k, rmse_cv = rmse, aicc = aicc)
  }))
  res$delta_aicc <- res$aicc - res$aicc[res$forma == "Lineal"]
  res$mejor_rmse <- !is.na(res$rmse_cv) & res$rmse_cv == min(res$rmse_cv, na.rm = TRUE)
  res$mejor_aicc <- !is.na(res$aicc) & res$aicc == min(res$aicc, na.rm = TRUE)
  res
}

#' Elasticidad de la cuota de voz respecto a la cuota de mercado
#'
#' Estima por mínimos cuadrados la regresión doble logarítmica
#' `ln SOV = c + gamma * ln SOM`. Un `gamma` < 1 indica economías de escala (las
#' marcas grandes invierten proporcionalmente menos); `gamma` = 1, paridad
#' (SOV proporcional a SOM); `gamma` > 1, deseconomías. Se excluyen las marcas
#' con SOV o SOM nulos. Con marcas de cuota muy pequeña y SOV muy ruidoso, el
#' logaritmo del SOV observado subestima el del esperado (desigualdad de Jensen),
#' de modo que `gamma` puede quedar sesgada al alza (las marcas pequeñas tienen
#' un `ln SOV` observado demasiado bajo); el estudio de
#' recuperación ([sov_valida_simulacion()]) cuantifica ese sesgo.
#'
#' @param som,sov Cuota de mercado y de voz (%).
#' @param nivel Nivel de confianza.
#' @return `NULL` si quedan menos de 4 marcas; si no, lista con `n`, `gamma`,
#'   `ic`, `p_igual1` (p-valor de H0: gamma = 1) y `excluidas`.
#' @examples
#' d <- sov_prepara(adage2019)
#' z <- d[d$caso == "auto_marcas", ]
#' sov_elasticidad(z$som, z$sov)
#' @export
sov_elasticidad <- function(som, sov, nivel = 0.95) {
  ok <- is.finite(som) & is.finite(sov) & som > 0 & sov > 0
  excl <- sum(!ok)
  x <- log(som[ok]); y <- log(sov[ok])
  if (length(x) < 4L || stats::var(x) == 0) return(NULL)
  m <- stats::lm(y ~ x)
  cf <- summary(m)$coefficients
  g <- unname(cf[2, 1]); se <- unname(cf[2, 2])
  ic <- unname(stats::confint(m, level = nivel)[2, ])
  list(n = length(x), gamma = g, se = se, ic = ic,
       p_igual1 = 2 * stats::pt(-abs((g - 1) / se), m$df.residual),
       excluidas = excl)
}

#' Contraste de homogeneidad de pendientes entre categorías
#'
#' Contraste F que compara el modelo de pendiente común (`esov ~ caso + som`)
#' con el de pendientes propias (`esov ~ caso * som`). Una `p` pequeña indica
#' que el efecto de la cuota sobre el ESOV difiere entre categorías, de modo
#' que un único coeficiente global no es apropiado.
#'
#' @param d Objeto `sov_datos` (o `data.frame` con `caso`, `som`, `esov`).
#' @return `NULL` si no hay al menos dos categorías con 4 marcas o faltan grados
#'   de libertad; si no, lista con `F`, `gl1`, `gl2`, `p`, `beta_comun`, `n` y
#'   `casos`.
#' @examples
#' sov_heterogeneidad(sov_prepara(adage2019))
#' @export
sov_heterogeneidad <- function(d) {
  d <- as.data.frame(unclass(d), stringsAsFactors = FALSE)
  d$caso <- as.character(d$caso)
  buenos <- names(which(table(d$caso) >= 4L))
  d <- d[d$caso %in% buenos, , drop = FALSE]
  if (length(buenos) < 2L) return(NULL)
  d$caso <- factor(d$caso)
  m1 <- stats::lm(esov ~ caso * som, data = d)
  if (m1$df.residual < 1L) return(NULL)
  m0 <- stats::lm(esov ~ caso + som, data = d)
  a <- stats::anova(m0, m1)
  list(F = a$F[2], gl1 = a$Df[2], gl2 = a$Res.Df[2], p = a$`Pr(>F)`[2],
       beta_comun = unname(stats::coef(m0)["som"]), n = nrow(d),
       casos = nlevels(d$caso))
}

#' Análisis completo ESOV-SOM por categoría
#'
#' Es la función principal del paquete. Para cada categoría con al menos 4
#' marcas estima ESOV = alfa + beta * SOM ([sov_ajusta()]), el diagnóstico de
#' influencia ([sov_influencia()]), las formas funcionales ([sov_formas()]), el
#' bootstrap de la pendiente ([sov_bootstrap()]) y la elasticidad
#' ([sov_elasticidad()]); además contrasta la homogeneidad de pendientes
#' ([sov_heterogeneidad()]).
#'
#' El resultado se explora con `print()`, [sov_interpreta()] (lectura en
#' lenguaje llano), [sov_tabla()], [sov_grafico()] y [sov_informe()].
#'
#' @section Interpretación de beta:
#' Como el SOM figura en ambos lados de la ecuación, beta se interpreta frente a
#' SOV = SOM (beta = 0), no frente a 0. Una beta negativa indica que las marcas
#' grandes invierten proporcionalmente menos (curva de intensidad publicitaria
#' de Jones, 1990); una beta positiva, lo contrario.
#'
#' @param datos Ruta de un CSV, `data.frame`, objeto `sov_datos` o simulado.
#' @param nivel Nivel de confianza (0,95 por defecto).
#' @param B Remuestras del bootstrap (2000 por defecto; `0` lo omite).
#' @param semilla Semilla del bootstrap.
#' @param incluir_resto Si `TRUE`, incluye la fila «resto del mercado»
#'   (generalmente no conviene: no es una marca).
#' @param jones Coeficientes (`alfa`, `beta`) de la recta de referencia de
#'   Jones que se dibuja y con la que se compara la pendiente.
#' @return Un objeto de clase `sov_analisis`.
#' @examples
#' x <- sov_analiza(adage2019, B = 200)
#' x
#' @export
sov_analiza <- function(datos, nivel = 0.95, B = 2000, semilla = 2019,
                        incluir_resto = FALSE, jones = .jones_slide) {
  if (inherits(datos, "sov_analisis")) return(datos)
  d <- sov_prepara(datos, incluir_resto = incluir_resto)
  d <- as.data.frame(unclass(d), stringsAsFactors = FALSE)
  d$caso <- factor(as.character(d$caso), levels = unique(as.character(d$caso)))
  casos <- levels(d$caso)
  if (!length(casos)) stop("No hay datos que analizar.", call. = FALSE)
  sectores <- lapply(casos, function(cs) {
    z <- d[d$caso == cs, , drop = FALSE]
    base <- list(caso = cs, sector = as.character(z$sector[1]), n = nrow(z), datos = z)
    aj <- sov_ajusta(z$som, z$esov, nivel)
    if (is.null(aj)) {
      base$ajuste <- NULL
      return(base)
    }
    c(base, list(
      ajuste = aj,
      influencia = sov_influencia(z$som, z$esov, z$marca, z$sov),
      formas = sov_formas(z$som, z$esov),
      bootstrap = sov_bootstrap(z$som, z$esov, B, nivel, semilla),
      elasticidad = sov_elasticidad(z$som, z$sov, nivel)
    ))
  })
  names(sectores) <- casos
  structure(list(
    datos = d, sectores = sectores,
    heterogeneidad = tryCatch(sov_heterogeneidad(d), error = function(e) NULL),
    jones = jones, nivel = nivel, B = B, semilla = semilla,
    incluir_resto = incluir_resto,
    simulado = any(d$simulado),
    simulacion = attr(datos, "simulacion"),
    version = as.character(utils::packageVersion("mediaSOV"))
  ), class = "sov_analisis")
}

#' Lectura en lenguaje llano de un análisis
#'
#' Redacta, para cada categoría, qué indican los coeficientes, cuán robustos
#' son y qué marcas merecen revisión. Es el texto que acompaña al informe.
#'
#' @param x Objeto `sov_analisis` (o datos admitidos por [sov_analiza()]).
#' @return Vector de caracteres: un párrafo por categoría y, si procede, uno
#'   sobre la homogeneidad de pendientes.
#' @examples
#' cat(sov_interpreta(sov_analiza(adage2019, B = 0)), sep = "\n\n")
#' @export
sov_interpreta <- function(x) {
  x <- sov_analiza(x, B = 0)
  jb <- unname(x$jones["beta"])
  niv <- fmt_es(x$nivel * 100, 0)
  out <- vapply(x$sectores, function(s) {
    if (is.null(s$ajuste)) {
      return(paste0(s$sector, ": solo hay ", s$n, " marcas y se necesitan al menos 4 para ",
                    "ajustar la recta; esta categor\u00eda se omite."))
    }
    a <- s$ajuste
    excluye0 <- a$ic_beta[1] > 0 || a$ic_beta[2] < 0
    base <- if (!excluye0) {
      "la pendiente no se distingue de cero, de modo que el gasto en voz es aproximadamente proporcional a la cuota (SOV \u2248 SOM + constante)"
    } else if (a$beta < 0) {
      "las marcas grandes invierten proporcionalmente menos que las peque\u00f1as (econom\u00edas de escala, en el sentido de la curva de Jones)"
    } else {
      "las marcas grandes invierten proporcionalmente m\u00e1s que las peque\u00f1as (lo contrario de la curva de Jones)"
    }
    jones_ok <- jb >= a$ic_beta[1] && jb <= a$ic_beta[2]
    cambia <- a$loo_rango[1] < 0 && a$loo_rango[2] > 0
    p1 <- paste0(
      s$sector, " (n = ", a$n, " marcas). La pendiente de ESOV sobre SOM es ",
      fmt_es(a$beta), " (IC ", niv, " %: ", fmt_ic(a$ic_beta), "; p ",
      ifelse(a$p_beta < 0.001, "", "= "), fmt_p(a$p_beta), ") y la recta explica el ",
      fmt_es(a$r2 * 100, 0), " % de la variabilidad (R\u00b2 = ", fmt_es(a$r2), "). ",
      toupper(substr(base, 1, 1)), substr(base, 2, nchar(base)), "; ",
      if (jones_ok) paste0("el valor de Jones (", fmt_es(jb), ") cae dentro del intervalo.")
      else paste0("el valor de Jones (", fmt_es(jb), ") queda fuera del intervalo.")
    )
    p2 <- paste0(
      "Con Theil-Sen la pendiente es ", fmt_es(a$ts_beta), "; al omitir cada marca por turno oscila entre ",
      fmt_es(a$loo_rango[1]), " y ", fmt_es(a$loo_rango[2]),
      if (cambia) ", y su signo cambia: el resultado depende de una sola marca y debe tomarse con cautela." else "."
    )
    p3 <- if (!is.na(a$som_umbral)) {
      paste0("El ESOV medio se anula cuando la cuota alcanza el ", fmt_es(a$som_umbral, 1),
             " %: por encima de ese umbral, las marcas invierten de media menos de lo que su cuota sugiere.")
    } else ""
    inf <- s$influencia
    al <- inf[inf$alerta != "", , drop = FALSE]
    p4 <- if (nrow(al)) {
      paste0("Marcas con alerta de influencia: ",
             paste0(al$marca, " (", al$alerta, ")", collapse = "; "),
             ". Conviene comprobar que sus datos son correctos y comparar la pendiente sin ellas (columna \u00abbeta sin la marca\u00bb).")
    } else "Ninguna marca supera los umbrales de influencia."
    p5 <- if (!is.null(s$bootstrap)) {
      paste0("En el bootstrap, la pendiente es negativa en el ", fmt_es(s$bootstrap$p_neg * 100, 0),
             " % de las remuestras.")
    } else ""
    paste(Filter(nzchar, c(p1, p2, p3, p4, p5)), collapse = " ")
  }, character(1))
  names(out) <- NULL
  h <- x$heterogeneidad
  if (!is.null(h)) {
    out <- c(out, paste0(
      "Homogeneidad de pendientes entre categor\u00edas: F(", h$gl1, "; ", h$gl2, ") = ", fmt_es(h$F),
      ", p ", ifelse(h$p < 0.001, "", "= "), fmt_p(h$p), ". ",
      if (h$p < 0.05) "Se rechaza que la pendiente sea com\u00fan: la relaci\u00f3n entre cuota de mercado y exceso de voz difiere entre categor\u00edas y no conviene resumirla con un \u00fanico coeficiente global."
      else "No se rechaza que la pendiente sea com\u00fan, aunque con pocas marcas por categor\u00eda el contraste tiene poca potencia."))
  }
  out
}

#' @export
print.sov_analisis <- function(x, ...) {
  nm <- sum(!x$datos$resto)
  cat("<sov_analisis> ESOV = alfa + beta * SOM  |  ", length(x$sectores), " categor\u00edas, ",
      nm, " marcas  |  IC ", x$nivel * 100, " %  |  bootstrap B = ", x$B, "\n", sep = "")
  if (isTRUE(x$simulado)) {
    cat("** DATOS SINT\u00c9TICOS: los resultados describen el proceso simulado, no el mercado real **\n")
  }
  print(sov_tabla(x, "resultados"))
  cat("\nInterpretaci\u00f3n detallada: sov_interpreta(x)\n")
  cat("Siguientes pasos: sov_grafico(x) | sov_tabla(x, \"influencia\") | sov_informe(x)\n")
  invisible(x)
}

#' @export
summary.sov_analisis <- function(object, ...) {
  print(object, ...)
  cat("\nINTERPRETACI\u00d3N POR CATEGOR\u00cdA\n\n")
  for (p in sov_interpreta(object)) {
    cat(paste(strwrap(p, width = max(40L, getOption("width"))), collapse = "\n"), "\n\n", sep = "")
  }
  invisible(object)
}
