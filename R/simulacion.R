.ids_estaticos <- c("jones_lineal", "paridad", "jones_heterogeneo", "potencia", "curvilinea")
.ids_dinamicos <- c("equilibrio", "elasticidad")

#' Catálogo de postulados del simulador
#'
#' Cada postulado es un proceso generador de datos (DGP) que formaliza un
#' supuesto de la literatura sobre la relación entre cuota de voz y cuota de
#' mercado. Todos comparten la estructura de mercado (tamaños de marca con
#' ley de potencia rango-tamaño; SOV con distribución de Dirichlet; cierre exacto de
#' mercado: SOM y SOV suman 100) y difieren en cómo el valor esperado del SOV depende del SOM.
#'
#' @return Un `data.frame` con el identificador (`id`), el nombre, la
#'   formulación, el tipo (estático o dinámico), los parámetros clave y las
#'   fuentes (claves de [sov_referencias()]).
#' @examples
#' sov_postulados()[, c("id", "nombre", "tipo")]
#' @export
sov_postulados <- function() {
  data.frame(
    id = c(.ids_estaticos, .ids_dinamicos),
    nombre = c("Curva de Jones (lineal)", "Paridad (SOV = SOM)", "Curva de Jones heterog\u00e9nea por categor\u00eda",
               "Ley de potencia", "Curvil\u00ednea (ESOV cuadr\u00e1tico)", "Equilibrio de cuotas",
               "Elasticidad de largo plazo"),
    formulacion = c(
      "ESOV = beta (SOM - media): las marcas peque\u00f1as invierten proporcionalmente m\u00e1s si beta < 0",
      "ESOV = 0 salvo ruido: cada marca invierte en proporci\u00f3n a su cuota",
      "Como jones_lineal, con beta_c ~ N(beta, tau^2) distinto en cada categor\u00eda",
      "SOV proporcional a SOM^gamma: gamma < 1 econom\u00edas de escala, gamma > 1 deseconom\u00edas",
      "ESOV = beta z + delta (z^2 - media(z^2)), z = SOM - media: efecto no lineal de la cuota",
      "d ln SOM = eta ln(SOV/SOM) + u con eta = 0: el exceso de voz no cambia la cuota",
      "d ln SOM = eta ln(SOV/SOM) + u con eta > 0: el exceso de voz hace crecer la cuota"),
    tipo = c(rep("est\u00e1tico", 5), rep("din\u00e1mico", 2)),
    parametros = c("beta, kappa", "kappa", "beta, tau_beta, kappa", "gamma, kappa",
                   "beta, delta, kappa", "eta, sigma_u", "eta, sigma_u"),
    fuentes = c("Jones1990; Hansen2005; Danenberg2016", "Jones1990; Danenberg2016", "Hansen2005",
                "Danenberg2016", "Hansen2005", "Graham2009; Danenberg2016", "Sethuraman2011; Binet2013"),
    stringsAsFactors = FALSE
  )
}

#' Calibra los parámetros del simulador con datos reales
#'
#' Estima, para cada categoría con al menos 4 marcas (con cuota de mercado y gasto
#' positivos para las estimaciones logarítmicas), la pendiente de la ley de
#' potencia rango-tamaño de las cuotas de mercado (`theta`), su dispersión, la
#' pendiente lineal de ESOV sobre SOM (`beta`), la elasticidad `gamma` y la
#' precisión `kappa` de la distribución de Dirichlet del SOV (estimador de
#' momentos a partir de los residuos de la recta: la varianza de la cuota
#' de voz de una marca de cuota esperada p es p(1-p)/(kappa+1), con
#' `kappa` mínimo 1). Resume con medianas entre categorías y estima
#' la heterogeneidad real de las pendientes (`tau_beta`) restando a la varianza
#' observada la varianza de muestreo de cada pendiente (estimador de momentos,
#' como en el metaanálisis de efectos aleatorios); si la resta es negativa,
#' `tau_beta = 0`.
#'
#' @param datos Datos admitidos por [sov_prepara()]. Si es `NULL` (por defecto),
#'   se usa [adage2019].
#' @param minimo Mínimo de marcas por categoría.
#' @return Un objeto `sov_calibracion` con `por_caso` (una fila por categoría)
#'   y `resumen` (lista de parámetros).
#' @examples
#' sov_calibra()
#' @export
sov_calibra <- function(datos = NULL, minimo = 4L) {
  d <- as.data.frame(unclass(sov_prepara(datos %||% .adage())), stringsAsFactors = FALSE)
  d$caso <- as.character(d$caso)
  filas <- lapply(unique(d$caso), function(cs) {
    z <- d[d$caso == cs & d$som > 0, , drop = FALSE]
    zp <- z[z$sov > 0, , drop = FALSE]
    if (nrow(z) < minimo || nrow(zp) < minimo) return(NULL)
    z <- z[order(-z$som), , drop = FALSE]
    rk <- seq_len(nrow(z))
    m_rs <- stats::lm(log(z$som) ~ log(rk))
    m_pw <- stats::lm(log(zp$sov) ~ log(zp$som))
    m_li <- stats::lm(z$esov ~ z$som)
    fit <- stats::fitted(m_li)
    p <- pmin(pmax((z$som + fit) / 100, 1e-4), 1 - 1e-4)
    r <- (z$sov - (z$som + fit)) / 100
    kappa <- max(1, (nrow(z) - 2) / sum(r^2 / (p * (1 - p))) - 1)
    data.frame(caso = cs, sector = as.character(z$sector[1]), n = nrow(z),
               theta = -unname(stats::coef(m_rs)[2]), sigma_forma = summary(m_rs)$sigma,
               gamma = unname(stats::coef(m_pw)[2]), kappa = kappa,
               beta = unname(stats::coef(m_li)[2]),
               se_beta = summary(m_li)$coefficients[2, 2], stringsAsFactors = FALSE)
  })
  tab <- do.call(rbind, filas)
  if (is.null(tab) || nrow(tab) < 2L) {
    stop("Para calibrar se necesitan al menos 2 categor\u00edas con ", minimo, " marcas o m\u00e1s.",
         call. = FALSE)
  }
  tau <- sqrt(max(0, stats::var(tab$beta) - mean(tab$se_beta^2)))
  resumen <- list(
    n_casos = nrow(tab), n_publicadas = as.integer(round(stats::median(tab$n))),
    theta = stats::median(tab$theta), theta_sd = stats::sd(tab$theta),
    sigma_forma = stats::median(tab$sigma_forma),
    gamma = stats::median(tab$gamma), kappa = stats::median(tab$kappa),
    beta = stats::median(tab$beta), tau_beta = tau
  )
  structure(list(por_caso = tab, resumen = resumen), class = "sov_calibracion")
}

#' @export
print.sov_calibracion <- function(x, ...) {
  cat("<sov_calibracion> ", x$resumen$n_casos, " categor\u00edas\n", sep = "")
  t <- x$por_caso
  t[, -(1:3)] <- lapply(t[, -(1:3)], fmt_es, d = 3)
  t <- t[, c("sector", "n", "theta", "sigma_forma", "gamma", "kappa", "beta", "se_beta")]
  names(t) <- c("Categor\u00eda", "n", "theta", "sigma forma", "gamma", "kappa", "beta", "EE beta")
  .imprime_bloques(t)
  r <- x$resumen
  cat("\nResumen (medianas entre categor\u00edas): theta = ", round(r$theta, 3), " (sd ", round(r$theta_sd, 3),
      "), sigma_forma = ", round(r$sigma_forma, 3), ", gamma = ", round(r$gamma, 3),
      ", kappa = ", round(r$kappa, 1), ", beta = ", round(r$beta, 3),
      ", tau_beta = ", round(r$tau_beta, 3), "\n", sep = "")
  invisible(x)
}

#' Parámetros de un postulado con su procedencia
#'
#' Devuelve los parámetros del simulador para un postulado, con la
#' **procedencia** de cada valor: calibrado con datos reales, tomado de la
#' slide 22 (Jones, 1990), supuesto por defecto o fijado por el usuario. Los
#' valores por defecto se calibran con [adage2019]; con `calibrar_con` se
#' recalibran con los datos propios del usuario.
#'
#' @section Parámetros:
#' \describe{
#'   \item{`n_categorias`}{Número de categorías (mercados) simuladas.}
#'   \item{`n_total_marcas`}{Marcas de cada mercado completo (cierre exacto a 100).}
#'   \item{`n_publicadas`}{Marcas de mayor cuota que se «publican»; el resto se
#'     devuelve como fila «resto del mercado» (`resto = TRUE`), como en Ad Age.}
#'   \item{`theta`, `theta_sd`, `sigma_forma`}{Ley de potencia rango-tamaño de
#'     las cuotas: SOM del rango r proporcional a r^(-theta) con ruido
#'     logarítmico `sigma_forma`; `theta` varía entre categorías con desviación
#'     típica `theta_sd` (Bae et al., 2024).}
#'   \item{`beta`}{Pendiente de ESOV sobre SOM (Jones, 1990).}
#'   \item{`tau_beta`}{Desviación típica de la pendiente entre categorías.}
#'   \item{`gamma`, `tau_gamma`}{Elasticidad de la ley de potencia y su
#'     dispersión entre categorías.}
#'   \item{`delta`}{Curvatura del postulado curvilíneo.}
#'   \item{`kappa`}{Precisión de la distribución de Dirichlet del SOV: la cuota
#'     de voz de una marca cuyo valor esperado es p tiene varianza
#'     p(1-p)/(kappa+1) (por tanto, mayor `kappa`, menos ruido). El Dirichlet
#'     garantiza cuotas en \[0, 1\] con suma exacta 100 y media igual al valor
#'     esperado del postulado (Morais et al., 2017).}
#' }
#'
#' @param postulado Identificador de [sov_postulados()] (los estáticos).
#' @param calibrar_con Datos con los que calibrar (por defecto [adage2019]).
#' @param ... Valores que sustituyen a los por defecto (por ejemplo
#'   `beta = -0.5`, `n_categorias = 20`). Quedan registrados como
#'   procedencia «usuario».
#' @return Objeto `sov_parametros` con `valores` (lista) y `procedencia`
#'   (`data.frame`).
#' @examples
#' p <- sov_parametros("jones_lineal")
#' p
#' sov_parametros("jones_lineal", beta = -0.5, n_categorias = 12)
#' @export
sov_parametros <- function(postulado = "jones_lineal", calibrar_con = NULL, ...) {
  postulado <- match.arg(postulado, .ids_estaticos)
  cal <- sov_calibra(calibrar_con)$resumen
  etiqueta_cal <- if (is.null(calibrar_con)) {
    paste0("Calibrado con AdAge 2019 (", cal$n_casos, " categor\u00edas)")
  } else {
    paste0("Calibrado con los datos aportados (", cal$n_casos, " categor\u00edas)")
  }
  v <- list(
    n_categorias = 6L, n_total_marcas = 30L, n_publicadas = cal$n_publicadas, resto = TRUE,
    theta = cal$theta, theta_sd = cal$theta_sd, sigma_forma = cal$sigma_forma,
    kappa = cal$kappa, beta = .jones_slide[["beta"]], tau_beta = 0,
    gamma = cal$gamma, tau_gamma = 0, delta = 0.004
  )
  pro <- c(
    n_categorias = "Supuesto por defecto (igual al n\u00famero de casos de AdAge 2019)",
    n_total_marcas = "Supuesto por defecto (Ad Age solo publica las marcas l\u00edderes)",
    n_publicadas = etiqueta_cal,
    resto = "Estructura de Ad Age (fila derivada)",
    theta = paste0(etiqueta_cal, "; forma de ley de potencia: Bae et al. (2024)"),
    theta_sd = paste0(etiqueta_cal, " (dispersi\u00f3n entre categor\u00edas)"),
    sigma_forma = etiqueta_cal,
    kappa = paste0(etiqueta_cal, " (precisi\u00f3n de Dirichlet, estimador de momentos); distribuci\u00f3n de cuotas: Morais et al. (2017)"),
    beta = "Recta de m\u00ednimos cuadrados ajustada a la tabla de Jones (1990, p. 40)",
    tau_beta = "Supuesto por defecto (sin heterogeneidad)",
    gamma = paste0(etiqueta_cal, " (mediana de la elasticidad log-log)"),
    tau_gamma = "Supuesto por defecto (sin heterogeneidad)",
    delta = "Supuesto de sensibilidad (sin respaldo emp\u00edrico)"
  )
  if (postulado == "paridad") {
    v$beta <- 0
    pro[["beta"]] <- "Definici\u00f3n del postulado (paridad: beta = 0)"
  }
  if (postulado == "jones_heterogeneo") {
    v$tau_beta <- cal$tau_beta
    pro[["tau_beta"]] <- paste0(etiqueta_cal, " (heterogeneidad real de pendientes, estimador de momentos)")
  }
  if (postulado == "potencia") {
    pro[["beta"]] <- "No se usa en este postulado"
  }
  ex <- list(...)
  if (length(ex)) {
    if (is.null(names(ex)) || any(!nzchar(names(ex)))) {
      stop("Los par\u00e1metros adicionales deben tener nombre, por ejemplo beta = -0.5.", call. = FALSE)
    }
    mal <- setdiff(names(ex), names(v))
    if (length(mal)) {
      stop("Par\u00e1metro(s) desconocido(s): ", paste(mal, collapse = ", "),
           ". Disponibles: ", paste(names(v), collapse = ", "), ".", call. = FALSE)
    }
    for (n in names(ex)) {
      v[[n]] <- ex[[n]]
      pro[[n]] <- "Fijado por el usuario"
    }
  }
  .valida_parametros(v)
  v$n_categorias <- as.integer(v$n_categorias)
  v$n_total_marcas <- as.integer(v$n_total_marcas)
  v$n_publicadas <- as.integer(v$n_publicadas)
  proc <- data.frame(parametro = names(v),
                     valor = vapply(v, function(z) if (is.logical(z)) as.character(z) else format(round(as.numeric(z), 4)), ""),
                     procedencia = unname(pro[names(v)]), stringsAsFactors = FALSE)
  structure(list(postulado = postulado, valores = v, procedencia = proc),
            class = "sov_parametros")
}

.valida_parametros <- function(v) {
  num1 <- function(x, nm) {
    if (!is.numeric(x) || length(x) != 1L || !is.finite(x)) {
      stop("El par\u00e1metro `", nm, "` debe ser un n\u00famero.", call. = FALSE)
    }
  }
  for (n in setdiff(names(v), "resto")) num1(v[[n]], n)
  if (!is.logical(v$resto) || length(v$resto) != 1L || is.na(v$resto)) {
    stop("El par\u00e1metro `resto` debe ser TRUE o FALSE.", call. = FALSE)
  }
  if (v$n_categorias < 1 || v$n_categorias > 200) stop("`n_categorias` debe estar entre 1 y 200.", call. = FALSE)
  if (v$n_publicadas < 4) stop("`n_publicadas` debe ser al menos 4 (m\u00ednimo para ajustar la recta).", call. = FALSE)
  if (v$n_total_marcas < v$n_publicadas || v$n_total_marcas > 500) {
    stop("`n_total_marcas` debe ser mayor o igual que `n_publicadas` y no superar 500.", call. = FALSE)
  }
  if (v$theta < 0 || v$theta_sd < 0 || v$sigma_forma < 0) stop("`theta`, `theta_sd` y `sigma_forma` no pueden ser negativos.", call. = FALSE)
  if (v$kappa < 0.5 || v$kappa > 1e6) stop("`kappa` debe estar entre 0,5 y 1.000.000.", call. = FALSE)
  if (v$beta <= -1 || v$beta > 2) stop("`beta` debe estar entre -1 (excluido) y 2.", call. = FALSE)
  if (v$tau_beta < 0 || v$tau_gamma < 0) stop("`tau_beta` y `tau_gamma` no pueden ser negativos.", call. = FALSE)
  if (v$gamma < 0 || v$gamma > 5) stop("`gamma` debe estar entre 0 y 5.", call. = FALSE)
  invisible(TRUE)
}

#' @export
print.sov_parametros <- function(x, ...) {
  nombre <- sov_postulados()$nombre[match(x$postulado, sov_postulados()$id)]
  cat("<sov_parametros> postulado: ", x$postulado, " (", nombre, ")\n", sep = "")
  for (i in seq_len(nrow(x$procedencia))) {
    p <- x$procedencia[i, ]
    cat("\n", p$parametro, " = ", p$valor, "\n", sep = "")
    cat(paste(strwrap(p$procedencia, width = max(40L, getOption("width")), indent = 2, exdent = 2), collapse = "\n"), "\n", sep = "")
  }
  invisible(x)
}

# Pendiente de una categoria: beta + tau * N(0,1), truncada a (-0.95, 2) para que la
# razon SOV/SOM del postulado lineal se mantenga positiva.
.beta_categoria <- function(v) {
  b <- v$beta + v$tau_beta * stats::rnorm(1)
  min(2, max(-0.95, b))
}

# Mercado completo de una categoría: cuotas SOM por ley de potencia rango-tamaño.
.mercado_som <- function(v) {
  K <- v$n_total_marcas
  theta_c <- max(0.05, stats::rnorm(1, v$theta, v$theta_sd))
  w <- seq_len(K)^(-theta_c) * exp(stats::rnorm(K, 0, v$sigma_forma))
  list(som = sort(100 * w / sum(w), decreasing = TRUE), theta = theta_c)
}

# Valor esperado (sin ruido) del SOV dado el SOM, con cierre exacto a 100.
.sov_esperado <- function(som, postulado, beta_c, gamma_c, delta) {
  K <- length(som)
  z <- som - 100 / K
  suelo <- 0
  if (postulado == "potencia") {
    m <- som^gamma_c
  } else {
    razon <- switch(postulado,
      paridad = rep(1, K),
      jones_lineal = , jones_heterogeneo = 1 + beta_c * z / som,
      curvilinea = 1 + (beta_c * z + delta * (z^2 - mean(z^2))) / som)
    suelo <- sum(razon < 0.05)
    m <- som * pmax(razon, 0.05)
  }
  list(sov = 100 * m / sum(m), suelo = suelo)
}

# SOV observado: Dirichlet con media igual al valor esperado (cierre exacto a 100 y
# esperanza sin sesgo) y precision kappa.
.sov_observado <- function(som, postulado, beta_c, gamma_c, delta, kappa) {
  e <- .sov_esperado(som, postulado, beta_c, gamma_c, delta)
  g <- stats::rgamma(length(som), shape = pmax(kappa * e$sov / 100, 1e-6))
  sov <- if (sum(g) > 0) 100 * g / sum(g) else e$sov
  list(sov = sov, esperado = e$sov, suelo = e$suelo)
}

#' Genera datos sintéticos de cuota de voz y de mercado
#'
#' Simula varias categorías de mercado con **cierre exacto** (las cuotas de
#' mercado y de voz de cada categoría suman 100, incluida la fila «resto del
#' mercado») siguiendo un postulado de la literatura ([sov_postulados()]). Los
#' tamaños de marca siguen una ley de potencia rango-tamaño; el SOV, con distribución de Dirichlet
#' de media igual a su valor esperado según el postulado, depende del SOM; después se
#' «publican» las marcas de mayor cuota y el resto se agrega, como hace Ad Age.
#'
#' @section Qué garantiza y qué no:
#' *Garantiza*: cuotas acotadas en \[0, 100\]; suma exacta 100 por categoría;
#' reproducibilidad con la misma semilla; verdad conocida (parámetros nominales
#' y pendiente lineal esperada de la muestra publicada, en `attr(, "simulacion")`);
#' y recuperación demostrable de los parámetros ([sov_valida_simulacion()]).
#' *No garantiza* que el mercado simulado se parezca al real: los datos
#' sintéticos **no son evidencia empírica** y no deben presentarse como casos
#' reales. Sirven para verificar métodos, calcular potencia y enseñar. Cada
#' fila lleva `simulado = TRUE` y los gráficos de datos simulados lo rotulan.
#'
#' @param postulado Uno de los postulados estáticos de [sov_postulados()].
#' @param parametros Objeto de [sov_parametros()]; por defecto, los del
#'   postulado.
#' @param semilla Semilla (el generador del usuario se restaura al terminar);
#'   `NULL` para usar el generador actual.
#' @param ... Parámetros que sustituyen a los por defecto (véase
#'   [sov_parametros()]), por ejemplo `beta = -0.5` o `n_categorias = 12`.
#' @return Un objeto `sov_datos` (con `simulado = TRUE`) y el atributo
#'   `simulacion`, que contiene el postulado, los parámetros con su
#'   procedencia, la semilla, la verdad por categoría y la versión del
#'   paquete. Se analiza con [sov_analiza()].
#' @examples
#' s <- sov_simula("jones_lineal", semilla = 1)
#' s
#' attr(s, "simulacion")$verdad
#' sov_analiza(s, B = 0)
#' @export
sov_simula <- function(postulado = c("jones_lineal", "paridad", "jones_heterogeneo",
                                     "potencia", "curvilinea"),
                       parametros = NULL, semilla = 2019L, ...) {
  postulado <- match.arg(postulado)
  if (is.null(parametros)) {
    parametros <- sov_parametros(postulado, ...)
  } else {
    if (!inherits(parametros, "sov_parametros")) {
      stop("`parametros` debe crearse con sov_parametros().", call. = FALSE)
    }
    if (length(list(...))) {
      stop("Use `parametros` o los par\u00e1metros sueltos, no ambos.", call. = FALSE)
    }
    if (parametros$postulado != postulado) {
      stop("Los par\u00e1metros son del postulado \"", parametros$postulado, "\", no de \"", postulado, "\".",
           call. = FALSE)
    }
  }
  v <- parametros$valores
  res <- .con_semilla(semilla, lapply(seq_len(v$n_categorias), function(i) {
    m <- .mercado_som(v)
    beta_c <- .beta_categoria(v)
    gamma_c <- max(0, v$gamma + v$tau_gamma * stats::rnorm(1))
    o <- .sov_observado(m$som, postulado, beta_c, gamma_c, v$delta, v$kappa)
    k <- v$n_publicadas
    pub <- seq_len(k)
    esp_pub <- o$esperado[pub] - m$som[pub]
    beta_pseudo <- unname(stats::coef(stats::lm(esp_pub ~ m$som[pub]))[2])
    cs <- sprintf("cat%02d", i)
    nm <- sprintf("Marca %02d", pub)
    d <- data.frame(caso = cs, sector = paste("Categor\u00eda", i), marca = nm,
                    som = m$som[pub], sov = o$sov[pub], resto = FALSE, stringsAsFactors = FALSE)
    if (v$resto) {
      d <- rbind(d, data.frame(caso = cs, sector = paste("Categor\u00eda", i), marca = "Resto del mercado",
                               som = 100 - sum(m$som[pub]), sov = 100 - sum(o$sov[pub]),
                               resto = TRUE, stringsAsFactors = FALSE))
    }
    list(d = d, verdad = data.frame(
      caso = cs, beta_nominal = beta_c, gamma_nominal = gamma_c, theta = m$theta,
      beta_lineal_publicadas = beta_pseudo, cobertura_som = sum(m$som[pub]),
      razones_suelo = o$suelo, stringsAsFactors = FALSE))
  }))
  d <- do.call(rbind, lapply(res, `[[`, "d"))
  d$esov <- d$sov - d$som
  d$simulado <- TRUE
  d <- d[, c("caso", "sector", "marca", "som", "sov", "esov", "resto", "simulado")]
  rownames(d) <- NULL
  d$caso <- factor(d$caso, levels = unique(d$caso))
  verdad <- do.call(rbind, lapply(res, `[[`, "verdad"))
  if (sum(verdad$razones_suelo) > 0) {
    warning("En ", sum(verdad$razones_suelo), " marca(s) el postulado daba un SOV esperado negativo; ",
            "se limit\u00f3 a un m\u00ednimo. Reduzca `beta` o `delta` para evitarlo.", call. = FALSE)
  }
  structure(d, class = c("sov_datos", "data.frame"),
            simulacion = list(postulado = postulado, parametros = parametros, semilla = semilla,
                              verdad = verdad,
                              paquete = as.character(utils::packageVersion("mediaSOV"))))
}

#' Genera un panel dinámico: ¿el exceso de voz hace crecer la cuota?
#'
#' Parte de un mercado simulado y lo hace evolucionar durante `periodos`
#' períodos con `d ln SOM = eta * ln(SOV / SOM) + u`, donde `u` es ruido normal de
#' desviación `sigma_u`; después renormaliza las cuotas a 100. En cada período
#' el SOV se genera según el postulado estático `base`. Con `eta = 0`
#' (postulado `"equilibrio"`) el exceso de voz no produce cambios de cuota,
#' como sostiene la evidencia de equilibrio de cuotas (Graham, 2009); con
#' `eta > 0` (postulado `"elasticidad"`) sí los produce.
#'
#' @section Valor por defecto de eta:
#' En `"elasticidad"`, `eta = 0,24`, la elasticidad media de largo plazo de la
#' publicidad de marca en el metaanálisis de Sethuraman et al. (2011). Es un
#' **supuesto operativo**: esa elasticidad se refiere al nivel de publicidad,
#' no a la razón SOV/SOM; el paquete la usa solo como orden de magnitud
#' plausible. Fíjese `eta` para explorar otros valores.
#'
#' @param postulado `"equilibrio"` (eta = 0) o `"elasticidad"` (eta = 0,24 por
#'   defecto).
#' @param base Postulado estático que genera el SOV en cada período.
#' @param periodos Número de períodos (mínimo 3).
#' @param eta Sustituye al valor por defecto de `eta`.
#' @param sigma_u Desviación típica del ruido de crecimiento.
#' @param parametros,semilla,... Como en [sov_simula()] (parámetros del
#'   postulado `base`).
#' @return Objeto `sov_datos` en formato largo con las columnas adicionales
#'   `periodo` y `d_ln_som` (`NA` en el último período) y el atributo
#'   `simulacion`. Se analiza con [sov_efecto_esov()].
#' @examples
#' p <- sov_simula_dinamica("elasticidad", periodos = 6, semilla = 1)
#' sov_efecto_esov(p)
#' @export
sov_simula_dinamica <- function(postulado = c("equilibrio", "elasticidad"),
                                base = "jones_lineal", periodos = 8L, eta = NULL,
                                sigma_u = 0.03, parametros = NULL, semilla = 2019L, ...) {
  postulado <- match.arg(postulado)
  base <- match.arg(base, .ids_estaticos)
  periodos <- as.integer(periodos)
  if (is.na(periodos) || periodos < 3L || periodos > 100L) stop("`periodos` debe estar entre 3 y 100.", call. = FALSE)
  if (!is.numeric(sigma_u) || length(sigma_u) != 1L || sigma_u < 0) stop("`sigma_u` debe ser un n\u00famero no negativo.", call. = FALSE)
  if (is.null(parametros)) parametros <- sov_parametros(base, ...)
  if (!inherits(parametros, "sov_parametros") || parametros$postulado != base) {
    stop("`parametros` debe ser de sov_parametros(\"", base, "\").", call. = FALSE)
  }
  eta_def <- if (postulado == "equilibrio") 0 else 0.24
  if (is.null(eta)) eta <- eta_def
  if (!is.numeric(eta) || length(eta) != 1L || !is.finite(eta)) stop("`eta` debe ser un n\u00famero.", call. = FALSE)
  if (postulado == "equilibrio" && eta != 0) {
    warning("En el postulado \"equilibrio\" eta debe ser 0; se usa eta = ", eta, " a petici\u00f3n del usuario.", call. = FALSE)
  }
  v <- parametros$valores
  res <- .con_semilla(semilla, lapply(seq_len(v$n_categorias), function(i) {
    m <- .mercado_som(v)
    beta_c <- .beta_categoria(v)
    gamma_c <- max(0, v$gamma + v$tau_gamma * stats::rnorm(1))
    som <- m$som
    k <- v$n_publicadas; pub <- seq_len(k)
    cs <- sprintf("cat%02d", i)
    filas <- vector("list", periodos)
    for (t in seq_len(periodos)) {
      o <- .sov_observado(som, base, beta_c, gamma_c, v$delta, v$kappa)
      nxt <- som * exp(eta * log(pmax(o$sov, 1e-8) / som) + stats::rnorm(length(som), 0, sigma_u))
      nxt <- 100 * nxt / sum(nxt)
      d <- data.frame(caso = cs, sector = paste("Categor\u00eda", i), marca = sprintf("Marca %02d", pub),
                      periodo = t, som = som[pub], sov = o$sov[pub], resto = FALSE,
                      d_ln_som = if (t < periodos) log(nxt[pub] / som[pub]) else NA_real_,
                      stringsAsFactors = FALSE)
      if (v$resto) {
        d <- rbind(d, data.frame(caso = cs, sector = paste("Categor\u00eda", i), marca = "Resto del mercado",
                                 periodo = t, som = 100 - sum(som[pub]), sov = 100 - sum(o$sov[pub]),
                                 resto = TRUE, d_ln_som = NA_real_, stringsAsFactors = FALSE))
      }
      filas[[t]] <- d
      som <- nxt
    }
    do.call(rbind, filas)
  }))
  d <- do.call(rbind, res)
  d$esov <- d$sov - d$som
  d$simulado <- TRUE
  d <- d[, c("caso", "sector", "marca", "periodo", "som", "sov", "esov", "resto", "d_ln_som", "simulado")]
  rownames(d) <- NULL
  d$caso <- factor(d$caso, levels = unique(d$caso))
  structure(d, class = c("sov_datos", "data.frame"),
            simulacion = list(postulado = postulado, base = base, parametros = parametros, eta = eta,
                              sigma_u = sigma_u, periodos = periodos, semilla = semilla,
                              paquete = as.character(utils::packageVersion("mediaSOV"))))
}

#' Estima el efecto del exceso de voz sobre el crecimiento de la cuota
#'
#' Con datos de panel (varios períodos por marca), regresa el crecimiento
#' logarítmico de la cuota, `d ln SOM`, sobre la razón logarítmica
#' `ln(SOV / SOM)` del período anterior, restando la media de cada categoría y
#' período (efectos fijos) para absorber la renormalización de las cuotas. El
#' coeficiente `eta` mide cuánto crece la cuota por cada unidad de exceso
#' logarítmico de voz. `eta = 0` es compatible con el equilibrio de cuotas.
#'
#' Requiere un panel: no se puede estimar con un único corte transversal como
#' [adage2019].
#'
#' @param panel Salida de [sov_simula_dinamica()] o un `data.frame` con las
#'   columnas `caso`, `periodo`, `som`, `sov`, `d_ln_som` (y opcionalmente
#'   `resto`).
#' @param nivel Nivel de confianza.
#' @return Lista con `eta`, `se`, `ic`, `p`, `n`, `grupos` y `gl`.
#' @examples
#' p <- sov_simula_dinamica("equilibrio", periodos = 6, semilla = 1)
#' sov_efecto_esov(p)
#' @export
sov_efecto_esov <- function(panel, nivel = 0.95) {
  d <- as.data.frame(unclass(panel), stringsAsFactors = FALSE)
  necesarias <- c("caso", "periodo", "som", "sov", "d_ln_som")
  if (!all(necesarias %in% names(d))) {
    stop("El panel necesita las columnas: ", paste(necesarias, collapse = ", "),
         ". Use sov_simula_dinamica() para generar uno.", call. = FALSE)
  }
  if (!is.null(d$resto)) d <- d[!d$resto, , drop = FALSE]
  d <- d[is.finite(d$d_ln_som) & d$som > 0 & d$sov > 0, , drop = FALSE]
  d$lr <- log(d$sov / d$som)
  g <- interaction(d$caso, d$periodo, drop = TRUE)
  y <- d$d_ln_som - stats::ave(d$d_ln_som, g)
  x <- d$lr - stats::ave(d$lr, g)
  sxx <- sum(x^2)
  if (sxx <= 0) stop("No hay variaci\u00f3n en ln(SOV/SOM) dentro de cada categor\u00eda y per\u00edodo.", call. = FALSE)
  b <- sum(x * y) / sxx
  gl <- nrow(d) - nlevels(g) - 1L
  if (gl < 1L) stop("Faltan grados de libertad: se necesitan m\u00e1s observaciones.", call. = FALSE)
  se <- sqrt(sum((y - b * x)^2) / gl / sxx)
  q <- stats::qt(1 - (1 - nivel) / 2, gl)
  list(eta = b, se = se, ic = b + c(-1, 1) * q * se, p = 2 * stats::pt(-abs(b / se), gl),
       n = nrow(d), grupos = nlevels(g), gl = gl)
}

#' Estudio de recuperación de parámetros (validación por simulación)
#'
#' Repite `R` veces «simular y analizar» con un postulado y mide si los
#' métodos del paquete recuperan la verdad conocida: sesgo y error cuadrático
#' medio de la pendiente (MCO y Theil-Sen), **cobertura** del intervalo de
#' confianza (qué proporción de intervalos contiene el valor verdadero; debería
#' ser cercana al nivel nominal), tasa de rechazo de `beta = 0` (potencia si el
#' efecto existe; tasa de falsos positivos si no existe) y la forma funcional
#' que elige el AICc. Para los postulados dinámicos evalúa [sov_efecto_esov()].
#'
#' La verdad de referencia de la pendiente MCO es la pendiente lineal esperada
#' de las marcas publicadas (`beta_lineal_publicadas`), que coincide con la
#' pendiente nominal en los postulados lineales y es la pendiente
#' «pseudoverdadera» cuando la forma verdadera no es lineal.
#'
#' @param postulado Identificador de [sov_postulados()] (estático o dinámico).
#' @param R Número de réplicas (200 por defecto; use 500 o más para informes).
#' @param nivel Nivel de confianza nominal.
#' @param semilla Semilla del estudio.
#' @param parametros Objeto de [sov_parametros()] (estáticos) o `NULL`.
#' @param B Remuestras del bootstrap de pares por ajuste para evaluar también
#'   su cobertura (0 por defecto: no se calcula; es lento). Solo en los
#'   postulados estáticos.
#' @param ... Parámetros que sustituyen a los por defecto (véase
#'   [sov_parametros()]); en los dinámicos, `eta`, `periodos` o `sigma_u`.
#' @return Objeto `sov_validacion` con `resumen` (tabla), `detalle` (una fila por
#'   réplica y categoría o por réplica) y los metadatos del estudio.
#' @examples
#' v <- sov_valida_simulacion("jones_lineal", R = 40, semilla = 1)
#' v
#' @export
sov_valida_simulacion <- function(postulado = "jones_lineal", R = 200L, nivel = 0.95,
                                  semilla = 2019L, parametros = NULL, B = 0L, ...) {
  R <- as.integer(R)
  if (is.na(R) || R < 10L) stop("`R` debe ser al menos 10.", call. = FALSE)
  dinamico <- postulado %in% .ids_dinamicos
  if (!dinamico) postulado <- match.arg(postulado, .ids_estaticos)
  if (dinamico) {
    extra <- list(...)
    det <- .con_semilla(semilla, do.call(rbind, lapply(seq_len(R), function(r) {
      p <- do.call(sov_simula_dinamica, c(list(postulado = postulado, semilla = NULL), extra))
      e <- sov_efecto_esov(p, nivel)
      eta0 <- attr(p, "simulacion")$eta
      data.frame(rep = r, eta_verdad = eta0, eta_hat = e$eta, lo = e$ic[1], hi = e$ic[2], p = e$p)
    })))
    res <- data.frame(
      medida = c("Sesgo medio de eta", "Error cuadr\u00e1tico medio (RMSE) de eta",
                 paste0("Cobertura del IC ", nivel * 100, " %"),
                 "Tasa de rechazo de eta = 0 (p < 0,05)"),
      valor = c(mean(det$eta_hat - det$eta_verdad), sqrt(mean((det$eta_hat - det$eta_verdad)^2)),
                mean(det$lo <= det$eta_verdad & det$hi >= det$eta_verdad), mean(det$p < 0.05)),
      error_mc = c(stats::sd(det$eta_hat - det$eta_verdad) / sqrt(R), NA_real_,
                   sqrt(mean(det$lo <= det$eta_verdad & det$hi >= det$eta_verdad) *
                          (1 - mean(det$lo <= det$eta_verdad & det$hi >= det$eta_verdad)) / R),
                   sqrt(mean(det$p < 0.05) * (1 - mean(det$p < 0.05)) / R)),
      stringsAsFactors = FALSE)
    return(structure(list(postulado = postulado, R = R, nivel = nivel, semilla = semilla,
                          resumen = res, detalle = det, dinamico = TRUE),
                     class = "sov_validacion"))
  }
  if (is.null(parametros)) parametros <- sov_parametros(postulado, ...)
  det <- .con_semilla(semilla, do.call(rbind, lapply(seq_len(R), function(r) {
    s <- sov_simula(postulado, parametros = parametros, semilla = NULL)
    ver <- attr(s, "simulacion")$verdad
    d <- as.data.frame(unclass(s), stringsAsFactors = FALSE)
    d <- d[!d$resto, , drop = FALSE]
    do.call(rbind, lapply(seq_len(nrow(ver)), function(i) {
      z <- d[d$caso == ver$caso[i], , drop = FALSE]
      a <- sov_ajusta(z$som, z$esov, nivel)
      el <- sov_elasticidad(z$som, z$sov, nivel)
      f <- sov_formas(z$som, z$esov)
      bo <- if (B > 0) sov_bootstrap(z$som, z$esov, B, nivel, semilla = NULL, theil_sen = FALSE) else NULL
      data.frame(rep = r, caso = ver$caso[i], beta_verdad = ver$beta_lineal_publicadas[i],
                 beta_nominal = ver$beta_nominal[i], gamma_verdad = ver$gamma_nominal[i],
                 beta_hat = a$beta, lo = a$ic_beta[1], hi = a$ic_beta[2], p = a$p_beta,
                 lo_hc3 = a$ic_beta_hc3[1], hi_hc3 = a$ic_beta_hc3[2], p_hc3 = a$p_beta_hc3,
                 lo_boot = if (is.null(bo)) NA_real_ else bo$ols[1],
                 hi_boot = if (is.null(bo)) NA_real_ else bo$ols[2],
                 ts_hat = a$ts_beta, gamma_hat = el$gamma, g_lo = el$ic[1], g_hi = el$ic[2],
                 forma_aicc = f$forma[which.min(f$aicc)], stringsAsFactors = FALSE)
    }))
  })))
  N <- nrow(det)
  mc_p <- function(p) sqrt(p * (1 - p) / N)
  cob <- mean(det$lo <= det$beta_verdad & det$hi >= det$beta_verdad)
  rech <- mean(det$p < 0.05)
  ok3 <- is.finite(det$lo_hc3)
  cob3 <- mean(det$lo_hc3[ok3] <= det$beta_verdad[ok3] & det$hi_hc3[ok3] >= det$beta_verdad[ok3])
  rech3 <- mean(det$p_hc3[ok3] < 0.05)
  sesgo <- det$beta_hat - det$beta_verdad
  sesgo_ts <- det$ts_hat - det$beta_verdad
  res <- data.frame(
    medida = c("Sesgo medio de beta (MCO)", "RMSE de beta (MCO)",
               paste0("Cobertura del IC ", nivel * 100, " % de beta (MCO cl\u00e1sico)"),
               "Tasa de rechazo de beta = 0 (MCO cl\u00e1sico, p < 0,05)",
               paste0("Cobertura del IC ", nivel * 100, " % de beta (robusto HC3)"),
               "Tasa de rechazo de beta = 0 (HC3, p < 0,05)",
               "Sesgo medio de beta (Theil-Sen)", "RMSE de beta (Theil-Sen)"),
    valor = c(mean(sesgo), sqrt(mean(sesgo^2)), cob, rech, cob3, rech3, mean(sesgo_ts), sqrt(mean(sesgo_ts^2))),
    error_mc = c(stats::sd(sesgo) / sqrt(N), NA_real_, mc_p(cob), mc_p(rech), mc_p(cob3), mc_p(rech3),
                 stats::sd(sesgo_ts) / sqrt(N), NA_real_),
    stringsAsFactors = FALSE)
  if (B > 0) {
    cb <- mean(det$lo_boot <= det$beta_verdad & det$hi_boot >= det$beta_verdad)
    res <- rbind(res, data.frame(medida = paste0("Cobertura del IC ", nivel * 100, " % de beta (bootstrap percentil, B = ", B, ")"),
                                 valor = cb, error_mc = mc_p(cb), stringsAsFactors = FALSE))
  }
  if (postulado %in% c("potencia", "paridad")) {
    gv <- if (postulado == "paridad") 1 else det$gamma_verdad
    gs <- det$gamma_hat - gv
    gc <- mean(det$g_lo <= gv & det$g_hi >= gv)
    res <- rbind(res, data.frame(
      medida = c("Sesgo medio de gamma", paste0("Cobertura del IC ", nivel * 100, " % de gamma")),
      valor = c(mean(gs), gc), error_mc = c(stats::sd(gs) / sqrt(N), mc_p(gc)),
      stringsAsFactors = FALSE))
  }
  tf <- table(factor(det$forma_aicc, levels = c("Lineal", "ln SOM", "Cuadr\u00e1tica")))
  attr(res, "forma_aicc") <- tf / sum(tf)
  structure(list(postulado = postulado, R = R, nivel = nivel, semilla = semilla,
                 resumen = res, detalle = det, parametros = parametros, dinamico = FALSE,
                 N = N), class = "sov_validacion")
}

#' @export
print.sov_validacion <- function(x, ...) {
  cat("<sov_validacion> postulado: ", x$postulado, " | R = ", x$R, " r\u00e9plicas",
      if (!x$dinamico) paste0(" | ", x$N, " ajustes") else "", " | semilla ", x$semilla, "\n", sep = "")
  r <- x$resumen
  r$valor <- fmt_es(r$valor, 4); r$error_mc <- fmt_es(r$error_mc, 4)
  names(r) <- c("Medida", "Valor", "Error Monte Carlo")
  .imprime_bloques(r)
  if (!x$dinamico) {
    tf <- attr(x$resumen, "forma_aicc")
    cat("\nForma funcional elegida por AICc: ",
        paste0(names(tf), " ", round(100 * as.numeric(tf), 1), " %", collapse = " | "), "\n", sep = "")
  }
  cat("\nLectura: el error_mc es el error de Monte Carlo (incertidumbre debida al n\u00famero de r\u00e9plicas). ",
      "Una cobertura cercana a ", x$nivel * 100, " % indica que los intervalos son fiables bajo este postulado; ",
      "una desviaci\u00f3n mayor que ~2 errores de Monte Carlo es una limitaci\u00f3n real del m\u00e9todo y debe comunicarse.\n", sep = "")
  invisible(x)
}
