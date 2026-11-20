test_that("la presentación conserva las tablas originales y las claves", {
  x <- sov_analiza(adage2019, B = 0)
  t <- sov_tabla(x, "resultados")
  expect_s3_class(t, "data.frame")
  antes <- t
  op <- options(width = 65)
  on.exit(options(op))
  salida <- capture.output(print(t))
  expect_gt(sum(grepl("Automoci", salida)), 1)
  expect_identical(t, antes)
  expect_match(paste(capture.output(print(x)), collapse = "\n"), "sov_interpreta")
  expect_match(paste(capture.output(summary(x)), collapse = "\n"), "INTERPRETACI")
})
