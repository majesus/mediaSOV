test_that("sov_prepara acepta el esquema simple y calcula ESOV", {
  d <- data.frame(categoria = rep("A", 5), marca = letters[1:5],
                  som = c(40, 25, 15, 12, 8), sov = c(30, 28, 18, 14, 10))
  p <- sov_prepara(d)
  expect_s3_class(p, "sov_datos")
  expect_equal(as.numeric(unclass(p)$esov), d$sov - d$som)
})

test_that("sov_lee detecta separador, decimal y codificación", {
  f <- tempfile(fileext = ".csv")
  con <- file(f, "wb")
  writeBin(c(as.raw(c(0xEF, 0xBB, 0xBF)),
             charToRaw("categoría;marca;som;sov\nA;m1;40,5;30,5\nA;m2;25,5;28\nA;m3;15;18\nA;m4;12;14\nA;m5;7;9,5\n")), con)
  close(con)
  d <- sov_lee(f)
  expect_equal(nrow(d), 5)
  expect_equal(as.numeric(unclass(sov_prepara(d))$som[1]), 40.5)

  g <- tempfile(fileext = ".csv")
  writeBin(iconv("categoria,marca,som,sov\nCafé,m1,40.5,30.5\nCafé,m2,25.5,28\nCafé,m3,15,18\nCafé,m4,12,14\nCafé,m5,7,9.5\n",
                 "UTF-8", "latin1"), g)
  expect_equal(nrow(sov_lee(g)), 5)
})

test_that("sov_prepara rechaza entradas inválidas con mensajes claros", {
  expect_error(sov_prepara(data.frame(x = 1)), "columna")
  expect_error(sov_analiza(tempfile()), "")
})

test_that("el CSV de ejemplo y la plantilla se leen", {
  expect_true(file.exists(sov_ejemplo()))
  x <- sov_analiza(sov_ejemplo(), B = 0)
  expect_s3_class(x, "sov_analisis")
  p <- sov_plantilla(tempfile(fileext = ".csv"))
  expect_true(file.exists(p))
  expect_s3_class(sov_analiza(p, B = 0), "sov_analisis")
})
