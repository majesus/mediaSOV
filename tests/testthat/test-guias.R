test_that("la guía de la marca reproduce los números de la slide 22 (Chevrolet)", {
  x <- sov_analiza(adage2019, B = 0)
  t <- sov_guia(x, "marca", "auto_marcas", "Chevrolet", formato = "texto")
  for (v in c("12,0 %", "10,5 %", "−1,5 pp", "13,8 %", "−3,3 pp", "8,9 %", "+1,6 pp", "15,0 %", "+3,0 pp", "+1,1 pp"))
    expect_match(t, v, fixed = TRUE, info = v)
  expect_match(t, "Paso 10 de 10", fixed = TRUE)
})

test_that("la guía del sector reproduce los números de la slide 22 (Automoción y Restauración)", {
  x <- sov_analiza(adage2019, B = 0)
  t <- sov_guia(x, "sector", "auto_marcas", formato = "texto")
  for (v in c("−0,35", "[−0,58; −0,12]", "0,007", "0,61", "45 parejas", "Ford, Toyota y Chevrolet", "McDonald's", "12,31", "−2,19", "cambia de signo"))
    expect_match(t, v, fixed = TRUE, info = v)
  expect_match(t, "Paso 11 de 11", fixed = TRUE)
})

test_that("los textos condicionales respetan los datos", {
  x <- sov_analiza(adage2019, B = 0)
  t <- sov_guia(x, "sector", "restaurantes", formato = "texto")
  expect_match(t, "no hay evidencia", ignore.case = TRUE)
  t2 <- sov_guia(x, "sector", "auto_marcas", formato = "texto")
  expect_match(t2, "Nunca cambia de signo", fixed = TRUE)
  expect_false(grepl("«cambia de signo» según qué marca", t2, fixed = TRUE))
})

test_that("las guías validan sus argumentos y rotulan los datos sintéticos", {
  x <- sov_analiza(adage2019, B = 0)
  expect_error(sov_guia(x, "marca", "no_existe"), "no encontrada")
  expect_error(sov_guia(x, "marca", "auto_marcas", "Inexistente"), "no encontrada")
  s <- sov_analiza(sov_simula("jones_lineal", semilla = 2), B = 0)
  expect_match(sov_guia(s, "sector"), "DATOS SINT", fixed = TRUE)
  expect_match(sov_guia(s, "marca"), "DATOS SINT", fixed = TRUE)
})

test_that("la guía se guarda como HTML autónomo con figuras", {
  skip_if_not_installed("knitr")
  x <- sov_analiza(adage2019, B = 0)
  f <- tempfile(fileext = ".html")
  suppressMessages(sov_guia(x, "marca", "auto_marcas", "Chevrolet", archivo = f))
  h <- paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  expect_match(h, "<!DOCTYPE html>", fixed = TRUE)
  expect_match(h, "data:image/png;base64,", fixed = TRUE)
})

test_that("las guías funcionan con una categoría de pocos datos y con una sola categoría", {
  d <- data.frame(categoria = "A", marca = letters[1:5], som = c(40, 25, 15, 12, 8), sov = c(30, 28, 18, 14, 10))
  x <- sov_analiza(d, B = 0)
  expect_match(sov_guia(x, "sector", formato = "texto"), "una sola categor", ignore.case = TRUE)
  expect_match(sov_guia(x, "marca", formato = "texto"), "Paso 10 de 10", fixed = TRUE)
})

test_that("sov_mapa dibuja el mapa SOV-SOM y valida sus argumentos", {
  f <- tempfile(fileext = ".png"); grDevices::png(f)
  expect_silent(sov_mapa(adage2019, "auto_marcas", marca = "Chevrolet"))
  expect_silent(sov_mapa(adage2019, "auto_marcas", jones = FALSE, valores = FALSE))
  grDevices::dev.off()
  expect_error(sov_mapa(adage2019, "no_existe"), "no encontrada")
  expect_error(sov_mapa(adage2019, "auto_marcas", marca = "Inexistente"), "no encontrada")
})
