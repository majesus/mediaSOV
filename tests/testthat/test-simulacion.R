test_that("el cierre del mercado es exacto en todos los postulados estáticos", {
  ids <- sov_postulados()$id[sov_postulados()$tipo == "estático"]
  for (id in ids) {
    s <- suppressWarnings(sov_simula(id, semilla = 7))
    d <- as.data.frame(unclass(s))
    expect_equal(as.numeric(tapply(d$som, d$caso, sum)), rep(100, length(unique(d$caso))), tolerance = 1e-8, info = id)
    expect_equal(as.numeric(tapply(d$sov, d$caso, sum)), rep(100, length(unique(d$caso))), tolerance = 1e-8, info = id)
    expect_true(all(d$simulado))
  }
})

test_that("la semilla reproduce y el estado del RNG del usuario se restaura", {
  set.seed(1); u <- runif(1); set.seed(1)
  a <- sov_simula("jones_lineal", semilla = 3)
  expect_equal(runif(1), u)
  b <- sov_simula("jones_lineal", semilla = 3)
  expect_equal(unclass(a)$sov, unclass(b)$sov)
  d <- sov_simula("jones_lineal", semilla = 4)
  expect_false(isTRUE(all.equal(unclass(a)$sov, unclass(d)$sov)))
})

test_that("los parámetros se pueden sustituir y se validan", {
  s <- sov_simula("jones_lineal", semilla = 1, kappa = 500)
  expect_equal(attr(s, "simulacion")$parametros$valores$kappa, 500)
  expect_error(sov_simula("jones_lineal", kappa = -1))
  expect_error(sov_simula("inexistente"))
  p <- sov_parametros("jones_lineal")
  expect_error(sov_simula("jones_lineal", parametros = p, kappa = 10), "no ambos")
})

test_that("los datos sintéticos se marcan como tales y se propagan al análisis", {
  s <- sov_simula("paridad", semilla = 2)
  expect_match(paste(capture.output(print(s)), collapse = " "), "SINT")
  expect_true(sov_analiza(s, B = 0)$simulado)
})

test_that("el simulador dinámico recupera eta", {
  skip_on_cran()
  d <- sov_simula_dinamica("elasticidad", semilla = 11)
  ef <- sov_efecto_esov(d)
  expect_true(is.finite(ef$eta))
  expect_lt(abs(ef$eta - 0.24), 0.1)
})

test_that("el estudio de recuperación funciona (R pequeño) y es reproducible", {
  skip_on_cran()
  v1 <- sov_valida_simulacion("jones_lineal", R = 15, semilla = 5)
  v2 <- sov_valida_simulacion("jones_lineal", R = 15, semilla = 5)
  expect_s3_class(v1, "sov_validacion")
  expect_equal(v1$resumen$valor, v2$resumen$valor)
  expect_true(all(c("medida", "valor", "error_mc") %in% names(v1$resumen)))
})

test_that("la calibración con los datos reales devuelve parámetros finitos", {
  cal <- sov_calibra()
  expect_true(all(is.finite(unlist(cal$resumen[c("theta", "kappa", "tau_beta")]))))
})

test_that("las referencias declaran su estado de verificación", {
  r <- sov_referencias()
  expect_true(all(c("cita", "verificacion") %in% names(r)))
  expect_true(all(nzchar(r$verificacion)))
})
