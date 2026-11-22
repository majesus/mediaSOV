# mediaSOV 0.1.0

* Referencias: la regla del 1,5 se atribuye a Peckham (1975/1981); la recta de Jones (α = 6,4; β = −0,38) se documenta como ajuste por mínimos cuadrados a la tabla de Jones (1990, p. 40); páginas de Jones (1990) unificadas en 38–42. El apartado 13 incorpora Schroer (1990): prima de voz necesaria para mover la cuota, latencia del efecto y límites de la lógica de voz relativa.

* README: nuevo apartado 13, «Cuánto SOV invertir: el método Peckham 1,5 ampliado». Modelo de ajuste de la cuota hacia la voz, fórmula cerrada de la SOV para un horizonte de dos años (mantenimiento en el objetivo más prima de crecimiento), recuperación de la regla de Peckham como caso particular, calibración de la velocidad de respuesta, ejemplo resuelto y trayectorias en los mapas ESOV–SOM y SOV–SOM. Las figuras `man/figures/README-peckham-*.png` son estáticas (se generan con `data-raw/figuras_peckham.py`, no al tejer `README.Rmd`).

* Presentación renovada: tablas Markdown en el README, resultados separados de las comprobaciones de robustez, columnas identificadoras repetidas en tablas anchas de consola, interpretación detallada en `summary()` y desplazamiento horizontal de tablas HTML. Los cálculos y campos numéricos se mantienen.

* Nueva función `sov_mapa()`: mapa SOV–SOM con zonas de cosecha e inversión, diagonal ESOV = 0 y aproximación lineal a la curva de Jones.

* Nueva función `sov_guia()`: dos guías paso a paso (marca y sector) en HTML o texto, con figuras incrustadas, texto condicionado a los datos y advertencias metodológicas. Integradas en `sov_informe()` (argumentos `guias`, `categoria`, `marca`, `epsilon`, `anios`, `inversion`) y en una pestaña del asistente Shiny.

* Primera versión: lectura robusta de CSV, análisis SOV–SOM (MCO, HC3, Theil-Sen, influencia, formas funcionales, bootstrap, elasticidad), tablas, gráficos, informe HTML y asistente Shiny.
* Simulación de datos sintéticos con postulados parametrizados, calibración con Ad Age (2019) y estudio de recuperación.
