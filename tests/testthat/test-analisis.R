test_that("la pendiente coincide con lm() y con las fórmulas manuales", {
  som <- c(30, 22, 15, 12, 9, 7, 5)
  sov <- c(24, 21, 16, 14, 11, 9, 5)
  esov <- sov - som
  a <- sov_ajusta(som, esov)
  m <- lm(esov ~ som)
  expect_equal(a$beta, unname(coef(m)[2]), tolerance = 1e-10)
  expect_equal(a$alfa, unname(coef(m)[1]), tolerance = 1e-10)
  expect_equal(a$ic_beta, unname(confint(m)[2, ]), tolerance = 1e-8)
  expect_equal(a$p_beta, summary(m)$coefficients[2, 4], tolerance = 1e-10)
  expect_equal(a$r2, summary(m)$r.squared, tolerance = 1e-10)
  b <- sum((som - mean(som)) * (esov - mean(esov))) / sum((som - mean(som))^2)
  expect_equal(a$beta, b, tolerance = 1e-12)
})

test_that("HC3 coincide con la fórmula sandwich calculada a mano", {
  set.seed(3); som <- runif(9, 2, 30); esov <- -0.3 * som + rnorm(9, 0, 2)
  m <- lm(esov ~ som); X <- model.matrix(m); e <- resid(m); h <- hatvalues(m)
  V <- solve(crossprod(X)) %*% crossprod(X * (e / (1 - h))) %*% solve(crossprod(X))
  a <- sov_ajusta(som, esov)
  expect_equal(a$se_beta_hc3, sqrt(V[2, 2]), tolerance = 1e-10)
})

test_that("Theil-Sen es la mediana de pendientes por pares", {
  x <- c(1, 2, 4, 7, 11); y <- c(2, 1, 5, 6, 14)
  pares <- combn(5, 2)
  pend <- apply(pares, 2, function(i) (y[i[2]] - y[i[1]]) / (x[i[2]] - x[i[1]]))
  expect_equal(unname(sov_theil_sen(x, y)["beta"]), median(pend))
})

test_that("con menos de 4 marcas no se ajusta y se avisa", {
  d <- data.frame(categoria = "A", marca = c("a", "b", "c"), som = c(50, 30, 20), sov = c(40, 35, 25))
  expect_warning(x <- sov_analiza(d, B = 0), "menos de 4")
  expect_null(x$sectores[[1]]$ajuste)
  expect_match(paste(sov_interpreta(x), collapse = " "), "4")
})

test_that("el bootstrap es reproducible y restaura el estado del RNG", {
  set.seed(10); a <- runif(1); set.seed(10)
  b1 <- sov_bootstrap(c(30, 22, 15, 12, 9, 7), c(-6, -1, 1, 2, 2, 2), B = 200, semilla = 5)
  expect_equal(runif(1), a)
  b2 <- sov_bootstrap(c(30, 22, 15, 12, 9, 7), c(-6, -1, 1, 2, 2, 2), B = 200, semilla = 5)
  expect_equal(b1$ols, b2$ols)
})

test_that("los datos reales reproducen los valores de la diapositiva 22", {
  x <- sov_analiza(adage2019, B = 0)
  auto <- x$sectores[[1]]$ajuste
  expect_equal(round(auto$beta, 2), -0.35)
  expect_equal(round(auto$ic_beta, 2), c(-0.58, -0.12))
})

test_that("tablas y textos se generan sin error", {
  x <- sov_analiza(adage2019, B = 0)
  for (t in c("resultados", "influencia", "formas", "elasticidad")) {
    expect_s3_class(sov_tabla(x, t), "data.frame")
    expect_type(sov_tabla(x, t, formato = "html"), "character")
  }
  expect_true(length(sov_interpreta(x)) >= 6)
  expect_s3_class(sov_glosario(), "data.frame")
})

test_that("los gráficos se dibujan", {
  x <- sov_analiza(adage2019, B = 0)
  pdf(NULL); on.exit(dev.off())
  expect_silent(sov_grafico(x, x$sectores[[1]]$caso))
  expect_silent(sov_grafico_bosque(x))
})
