#' Referencias bibliográficas del paquete
#'
#' Devuelve las fuentes en las que se apoyan los postulados del simulador y los
#' métodos estadísticos.
#'
#' @return Un `data.frame` con las columnas `clave` y `cita`.
#' @examples
#' sov_referencias()
#' @export
sov_referencias <- function() {
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
    stringsAsFactors = FALSE
  )
}
