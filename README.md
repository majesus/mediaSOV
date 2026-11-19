# mediaSOV

Análisis y simulación de la relación entre **cuota de voz (SOV)** y **cuota de mercado (SOM)** en planificación de medios, pensado para usarse sin conocimientos avanzados de R.

## Instalación

```r
install.packages("remotes")
remotes::install_github("majesus/mediaSOV", build_vignettes = FALSE)
```

## Empezar en 60 segundos

```r
library(mediaSOV)
sov_demo()          # recorrido guiado con datos reales y sintéticos
sov_asistente()     # aplicación en el navegador, sin escribir código
```

Con sus datos (una fila por marca, al menos 4 marcas por categoría):

```r
sov_plantilla("mis_datos.csv")      # archivo de muestra que Excel abre bien
x <- sov_analiza("mis_datos.csv")
x                                   # resumen
cat(sov_interpreta(x), sep = "\n\n")# lectura en lenguaje llano
sov_informe(x)                      # informe HTML autocontenido
```

## Qué incluye

El análisis estima ESOV = SOV − SOM = α + β·SOM por categoría con mínimos cuadrados, errores clásicos y robustos (HC3), Theil-Sen, validación dejando una marca fuera, diagnóstico de influencia, bootstrap de pares, formas funcionales alternativas (AICc y validación cruzada), elasticidad log-log y contraste de homogeneidad de pendientes. La curva de referencia de Jones (1990) se toma de una diapositiva docente y **no se ha verificado contra el original**.

## Datos sintéticos

`sov_simula()` genera datos con verdad conocida bajo cinco postulados estáticos (curva de Jones lineal, paridad, Jones heterogénea, ley de potencia, curvilínea) y dos dinámicos (`sov_simula_dinamica()`: equilibrio y elasticidad). Los parámetros son editables y llevan su procedencia (`sov_parametros()`); `sov_calibra()` los calibra con los datos reales incluidos y `sov_valida_simulacion()` mide sesgo, error cuadrático y cobertura de cada método. Los datos sintéticos **no son evidencia empírica** y todos los resultados que de ellos derivan se rotulan como tales. La elasticidad η = 0,24 de la simulación dinámica es un supuesto operativo, no una estimación propia. Las referencias, con su estado de verificación, están en `sov_referencias()`.

## Limitaciones

Las cuotas suman 100 %, con 6–10 marcas por categoría la potencia es baja, y una asociación no implica causalidad. En simulaciones de referencia, el intervalo clásico de β cubre alrededor del 84 % bajo el postulado de Jones lineal con los parámetros calibrados; el robusto HC3 cubre cerca del 94 %. Compruebe estas cifras con `sov_valida_simulacion()`.

## Cita y licencia

`citation("mediaSOV")`. Licencia MIT.
