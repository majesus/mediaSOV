test_that("la senda constante reproduce la fórmula cerrada del apartado 13.3", {
  formula <- function(s0, obj, k, alfa, beta, T = 2) {
    w <- 1 / (1 - exp(-k * (1 + beta) * T))
    alfa + (1 + beta) * obj + (1 + beta) * (w - 1) * (obj - s0)
  }
  p <- sov_plan(8, 9, 10)
  expect_equal(p$periodos$sov, rep(formula(8, 10, 0.55, 0, 0), 2))
  j <- sov_plan(8, 9, 10, referencia = "jones")
  expect_equal(j$periodos$sov[1], formula(8, 10, 0.55, 6.4, -0.38))
  expect_equal(round(j$periodos$sov[1], 1), 13.9)
  expect_equal(round(sov_plan(8, 9, 10, k = 0.05)$periodos$sov[1], 1), 29.0)
  expect_equal(p$resumen$som_final, 10)
  expect_equal(round(p$resumen$indice), 125)
})

test_that("la regla de Peckham es el caso particular con s0 próxima a cero", {
  p <- sov_plan(1e-6, 9, 10, k = log(3) / 2)
  expect_equal(p$periodos$sov[1], 15, tolerance = 1e-5)
})

test_that("el reparto trimestral constante coincide con el anual", {
  a <- sov_plan(8, 9, 10)
  t <- sov_plan(8, 9, 10, periodos = 4)
  expect_equal(nrow(t$periodos), 8L)
  expect_equal(unique(round(t$periodos$sov, 10)), round(a$periodos$sov[1], 10))
  expect_equal(t$resumen$presupuesto_total, a$resumen$presupuesto_total)
  expect_equal(t$periodos$som_fin[c(4, 8)], a$periodos$som_fin)
  expect_equal(t$periodos$periodo[1], "Año 1, T1")
})

test_that("la senda de mínimo coste alcanza el objetivo con menos presupuesto", {
  for (ref in c("paridad", "jones")) {
    cte <- sov_plan(8, 9, 10, referencia = ref, periodos = 4)
    mc <- sov_plan(8, 9, 10, referencia = ref, periodos = 4, senda = "minimo_coste")
    expect_equal(mc$resumen$som_final, 10, tolerance = 1e-8)
    expect_lt(mc$resumen$presupuesto_total, cte$resumen$presupuesto_total)
    expect_true(all(diff(mc$periodos$sov) >= -1e-9))
    expect_true(min(mc$periodos$sov) >= 8 + (ref == "jones") * (6.4 - 0.38 * 8) - 1e-9)
  }
})

test_that("ninguna redistribución factible abarata la senda de mínimo coste", {
  mc <- sov_plan(8, 9, 10, referencia = "jones", periodos = 4, senda = "minimo_coste")
  p <- mc$parametros
  dec <- exp(-p$k * (1 + p$beta) / 4)
  g_ult <- (1 - dec) / (1 + p$beta)
  cuota <- function(v) {
    s <- p$som
    for (x in v) s <- s * dec + (1 - dec) * (x - p$alfa) / (1 + p$beta)
    s
  }
  coste <- function(v) sum(p$inversion_competencia / 4 * v / (100 - v))
  v0 <- mc$periodos$sov
  set.seed(11)
  for (i in 1:300) {
    v <- v0 + stats::rnorm(8, 0, 0.3)
    v[8] <- v[8] + (p$objetivo - cuota(v)) / g_ult
    if (all(v >= min(v0) - 1e-9)) expect_gte(coste(v), coste(v0) - 1e-9)
  }
})

test_that("con retardo, la voz final se fija en el mantenimiento del objetivo", {
  r <- sov_plan(8, 9, 10, periodos = 4, retardo = 0.5)
  expect_equal(r$periodos$sov[7:8], c(10, 10))
  expect_false(any(r$periodos$actua_antes_del_cierre[7:8]))
  expect_equal(r$resumen$som_final, 10)
  # Durante el retardo la cuota responde a la SOV actual (9 % frente a 8 % de cuota).
  expect_gt(r$periodos$som_fin[1], 8)
  expect_warning(sov_plan(8, 9, 10, periodos = 4, retardo = 0.6), "redondeado")
  expect_error(sov_plan(8, 9, 10, retardo = 2), "menor que el horizonte")
})

test_that("la inversión de la competencia y la recta propia se respetan", {
  a <- sov_plan(8, 9, 10, inversion = 50)
  expect_equal(a$resumen$presupuesto_total, sov_plan(8, 9, 10)$resumen$presupuesto_total / 2)
  b <- sov_plan(8, 9, 10, alfa = 6.4, beta = -0.38)
  expect_equal(b$periodos$sov, sov_plan(8, 9, 10, referencia = "jones")$periodos$sov)
  x <- sov_plan(8, 9, 10, periodos = 4, inversion_competencia = rep(c(1000, 1200), 4))
  expect_equal(x$parametros$inversion_competencia, rep(c(1000, 1200), 4))
})

test_that("las entradas imposibles producen errores claros", {
  expect_error(sov_plan(8, 9, 95, k = 0.05), "100 %")
  expect_error(sov_plan(8, 9, 10, alfa = 1), "a la vez")
  expect_error(sov_plan(8, 9, 10, beta = -1.2, alfa = 0), "1 \\+ beta")
  expect_error(sov_plan(8, 9, 10, periodos = 1.5), "entero")
  expect_error(sov_plan(8, 9, 10, periodos = 4, senda = "minimo_coste", sov_minima = 15),
               "supera el objetivo")
})

test_that("print y plot funcionan", {
  p <- sov_plan(8, 9, 10, periodos = 4, senda = "minimo_coste", retardo = 0.5)
  expect_output(print(p), "mínimo coste")
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(f)
  expect_silent(plot(p))
  grDevices::dev.off()
  unlink(f)
})
