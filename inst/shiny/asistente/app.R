library(shiny)
library(mediaSOV)
`%||%` <- function(a, b) if (is.null(a) || is.na(a)) b else a

ui <- fluidPage(
  titlePanel("mediaSOV: cuota de voz frente a cuota de mercado"),
  sidebarLayout(
    sidebarPanel(
      radioButtons("origen", "1. Datos",
        c("Ejemplo real (Ad Age 2019)" = "ejemplo",
          "Subir mi archivo CSV" = "csv",
          "Generar datos sintéticos" = "sim")),
      conditionalPanel("input.origen == 'csv'",
        fileInput("archivo", "Archivo CSV", accept = c(".csv", ".txt")),
        helpText("Columnas: categoría, marca, cuota de mercado (SOM) y cuota de voz (SOV). ",
                 "Descargue la plantilla si lo necesita."),
        downloadButton("plantilla", "Descargar plantilla")),
      conditionalPanel("input.origen == 'sim'",
        selectInput("postulado", "Postulado", choices = NULL),
        helpText(textOutput("formulacion")),
        numericInput("semilla", "Semilla (reproducibilidad)", 2019, min = 1, step = 1)),
      sliderInput("nivel", "2. Nivel de confianza", 0.80, 0.99, 0.95, step = 0.01),
      numericInput("B", "Remuestras bootstrap", 500, min = 0, max = 5000, step = 100),
      actionButton("go", "Analizar", class = "btn-primary"),
      hr(),
      downloadButton("informe", "Descargar informe HTML")
    ),
    mainPanel(
      uiOutput("aviso"),
      tabsetPanel(
        tabPanel("Lectura", br(), uiOutput("lectura")),
        tabPanel("Resultados", br(), htmlOutput("t_res")),
        tabPanel("Gráfico", br(),
                 selectInput("cat", "Categoría", choices = NULL),
                 plotOutput("grafico", height = "480px")),
        tabPanel("Influencia", br(), htmlOutput("t_inf")),
        tabPanel("Guía paso a paso", br(),
                 fluidRow(
                   column(4, radioButtons("g_tipo", "Guía",
                     c("1. ¿Invierte esta marca lo que cabría esperar? (una marca)" = "marca",
                       "2. ¿Podemos fiarnos de la recta? (la categoría)" = "sector"))),
                   column(4, selectInput("g_cat", "Categoría", choices = NULL),
                             selectInput("g_marca", "Marca de ejemplo", choices = NULL)),
                   column(4, conditionalPanel("input.g_tipo == 'marca'",
                     numericInput("g_inv", "Cambio de inversión simulado (%)", 50, step = 10),
                     numericInput("g_anios", "Horizonte (años)", 3, min = 1, max = 10),
                     numericInput("g_eps", "Elasticidad supuesta (ε)", 0.05, min = 0, max = 0.5, step = 0.01)))),
                 uiOutput("guia")),
        tabPanel("Glosario", br(), tableOutput("glosario")),
        tabPanel("Ayuda", br(), htmlOutput("ayuda"))
      )
    )
  )
)

server <- function(input, output, session) {
  post <- sov_postulados()
  est <- post[post$tipo == "estático", ]
  updateSelectInput(session, "postulado", choices = stats::setNames(est$id, est$nombre))
  output$formulacion <- renderText({
    req(input$postulado); est$formulacion[est$id == input$postulado]
  })
  output$plantilla <- downloadHandler(
    "plantilla_sov.csv", function(file) file.copy(sov_plantilla(tempfile(fileext = ".csv")), file))

  analisis <- eventReactive(input$go, {
    datos <- switch(input$origen,
      ejemplo = adage2019,
      csv = { req(input$archivo); input$archivo$datapath },
      sim = sov_simula(input$postulado, semilla = input$semilla))
    withProgress(message = "Analizando...", {
      sov_analiza(datos, nivel = input$nivel, B = input$B)
    })
  }, ignoreNULL = FALSE)

  observe({
    x <- analisis()
    ok <- Filter(function(s) !is.null(s$ajuste), x$sectores)
    updateSelectInput(session, "cat", choices = stats::setNames(
      vapply(ok, function(s) s$caso, ""), vapply(ok, function(s) s$sector, "")))
  })
  tryx <- function(expr) tryCatch(expr, error = function(e) {
    showNotification(conditionMessage(e), type = "error", duration = 15); NULL })

  observe({
    x <- analisis()
    ok <- Filter(function(s) !is.null(s$ajuste), x$sectores)
    updateSelectInput(session, "g_cat", choices = stats::setNames(
      vapply(ok, function(s) s$caso, ""), vapply(ok, function(s) s$sector, "")))
  })
  observeEvent(input$g_cat, {
    x <- analisis(); req(input$g_cat, input$g_cat %in% names(x$sectores))
    z <- x$sectores[[input$g_cat]]$datos
    updateSelectInput(session, "g_marca", choices = z$marca, selected = z$marca[which.max(z$som)])
  })
  output$guia <- renderUI({
    x <- tryx(analisis()); req(x, input$g_cat, input$g_marca)
    req(input$g_marca %in% x$sectores[[input$g_cat]]$datos$marca)
    HTML(sov_guia(x, input$g_tipo, categoria = input$g_cat, marca = input$g_marca,
                  epsilon = input$g_eps %||% 0.05, anios = input$g_anios %||% 3, inversion = input$g_inv %||% 50))
  })
  output$aviso <- renderUI({
    x <- tryx(analisis()); req(x)
    if (isTRUE(x$simulado)) div(style = "border:2px solid #b00020;background:#fdecea;padding:8px;margin-bottom:10px",
      strong("DATOS SINTÉTICOS: no son evidencia empírica."))
  })
  output$lectura <- renderUI({
    x <- tryx(analisis()); req(x)
    tagList(lapply(sov_interpreta(x), function(p) tags$p(p)))
  })
  output$t_res <- renderUI({ x <- tryx(analisis()); req(x); HTML(sov_tabla(x, "resultados", formato = "html")) })
  output$t_inf <- renderUI({ x <- tryx(analisis()); req(x); HTML(sov_tabla(x, "influencia", formato = "html")) })
  output$grafico <- renderPlot({ x <- tryx(analisis()); req(x, input$cat); sov_grafico(x, input$cat) })
  output$glosario <- renderTable(sov_glosario(), striped = TRUE)
  output$ayuda <- renderUI(HTML(paste0(
    "<p>Pasos: elija el origen de los datos, pulse <b>Analizar</b> y revise las pestañas. ",
    "El informe HTML incluye tablas, gráficos, glosario, limitaciones y referencias.</p>",
    "<p><b>Datos propios.</b> El CSV necesita categoría, marca, SOM y SOV en porcentaje. ",
    "Admite coma o punto y coma, coma o punto decimal y codificación UTF-8 o Latin-1.</p>",
    "<p><b>Datos sintéticos.</b> Cada postulado es un supuesto teórico; los resultados ilustran el método, ",
    "no el mundo real.</p>")))
  output$informe <- downloadHandler("informe_sov.html", function(file) {
    x <- tryx(analisis()); req(x)
    withProgress(message = "Generando informe...", sov_informe(x, archivo = file, abrir = FALSE))
  })
}
shinyApp(ui, server)
