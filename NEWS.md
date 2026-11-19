# mediaSOV 0.1.0

* Nueva función `sov_mapa()`: mapa SOV–SOM con zonas de cosecha e inversión, diagonal ESOV = 0 y aproximación lineal a la curva de Jones.

* Nueva función `sov_guia()`: dos guías paso a paso (marca y sector) en HTML o texto, con figuras incrustadas, texto condicionado a los datos y advertencias metodológicas. Integradas en `sov_informe()` (argumentos `guias`, `categoria`, `marca`, `epsilon`, `anios`, `inversion`) y en una pestaña del asistente Shiny.

* Primera versión: lectura robusta de CSV, análisis SOV–SOM (MCO, HC3, Theil-Sen, influencia, formas funcionales, bootstrap, elasticidad), tablas, gráficos, informe HTML y asistente Shiny.
* Simulación de datos sintéticos con postulados parametrizados, calibración con Ad Age (2019) y estudio de recuperación.
