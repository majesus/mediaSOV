#' Referencias bibliográficas del paquete y estado de su verificación
#'
#' Devuelve las fuentes en las que se apoyan los postulados del simulador y los
#' métodos estadísticos, con una columna que declara **qué se ha verificado**
#' con herramientas de búsqueda bibliográfica y qué procede de la bibliografía
#' del autor o de referencias clásicas. Las fuentes no verificadas deben
#' contrastarse con el original antes de citarlas.
#'
#' @return Un `data.frame` con las columnas `clave`, `cita` y `verificacion`.
#' @examples
#' sov_referencias()[, c("clave", "verificacion")]
#' @export
sov_referencias <- function() {
  v_c <- "Existencia, t\u00edtulo, revista y a\u00f1o contrastados en Consensus (19-nov-2026); volumen y p\u00e1ginas, de la bibliograf\u00eda del autor."
  v_p <- "Existencia, t\u00edtulo, revista y a\u00f1o contrastados en Consensus (19-nov-2026); sin volumen ni p\u00e1ginas."
  v_k <- "Referencia cl\u00e1sica citada de memoria; no recuperada con herramientas de b\u00fasqueda. Verif\u00edquese antes de citar."
  v_s <- "Citada en la slide 22 del autor; no verificada con herramientas de b\u00fasqueda. Verif\u00edquese antes de citar."
  data.frame(
    clave = c("Jones1990", "Hansen2005", "Danenberg2016", "Sethuraman2011", "Graham2009", "Bae2024",
              "Morais2017", "Binet2007", "Binet2013", "Theil1950", "Sen1968", "Cook1977", "Belsley1980",
              "Hurvich1989", "Efron1979"),
    cita = c(
      "Jones, J. P. (1990). Ad spending: Maintaining market share. Harvard Business Review, 68(1), 38-42.",
      "Hansen, F., & Christensen, L. B. (2005). Share of voice/share of market and long-term advertising effects. International Journal of Advertising, 24(3), 297-320.",
      "Danenberg, N., Kennedy, R., Beal, V., & Sharp, B. (2016). Advertising budgeting: A reinvestigation of the evidence on brand size and spend. Journal of Advertising, 45(1), 139-146.",
      "Sethuraman, R., Tellis, G. J., & Briesch, R. A. (2011). How well does advertising work? Generalizations from meta-analysis of brand advertising elasticities. Journal of Marketing Research, 48(3), 457-471.",
      "Graham, C. (2009). What's the point of marketing anyway? The prevalence, temporal extent and implications of long-term market share equilibrium. Journal of Marketing Management.",
      "Bae, Y. H., et al. (2024). Category-level drivers of the market share-rank power law relationship. European Journal of Marketing.",
      "Morais, J., Thomas-Agnan, C., & Simioni, M. (2017). Using compositional and Dirichlet models for market share regression. Journal of Applied Statistics.",
      "Binet, L., & Field, P. (2007). Marketing in the Era of Accountability. WARC.",
      "Binet, L., & Field, P. (2013). The Long and the Short of It. IPA.",
      "Theil, H. (1950). A rank-invariant method of linear and polynomial regression analysis. Nederlandse Akademie van Wetenschappen, Proceedings, 53, 386-392, 521-525, 1397-1412.",
      "Sen, P. K. (1968). Estimates of the regression coefficient based on Kendall's tau. Journal of the American Statistical Association, 63(324), 1379-1389.",
      "Cook, R. D. (1977). Detection of influential observation in linear regression. Technometrics, 19(1), 15-18.",
      "Belsley, D. A., Kuh, E., & Welsch, R. E. (1980). Regression Diagnostics. Wiley.",
      "Hurvich, C. M., & Tsai, C.-L. (1989). Regression and time series model selection in small samples. Biometrika, 76(2), 297-307.",
      "Efron, B. (1979). Bootstrap methods: Another look at the jackknife. The Annals of Statistics, 7(1), 1-26."
    ),
    verificacion = c(v_c, v_c, v_c, v_c, v_p, v_p, v_p, v_s, v_s, v_k, v_k, v_k, v_k, v_k, v_k),
    stringsAsFactors = FALSE
  )
}
