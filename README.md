
# mediaSOV

**Análisis y simulación de la relación entre cuota de voz (SOV) y cuota
de mercado (SOM) en planificación de medios**, diseñado para usarse sin
conocimientos avanzados de R y con el rigor metodológico que exige una
publicación académica o un informe profesional.

> Las cifras de las tablas proceden de los resultados ejecutados en la
> versión anterior del README. El archivo [README.Rmd](README.Rmd)
> permite regenerarlas con knitr; se ha renovado su presentación sin
> cambiar las estimaciones.

## Índice

1.  [¿Qué hace el paquete?](#1-qué-hace-el-paquete)
2.  [Instalación](#2-instalación)
3.  [Inicio rápido (2 minutos)](#3-inicio-rápido-2-minutos)
4.  [Sus propios datos](#4-sus-propios-datos)
5.  [Análisis: `sov_analiza()` y su
    lectura](#5-análisis-sov_analiza-y-su-lectura)
6.  [Tablas](#6-tablas)
7.  [Gráficos](#7-gráficos)
8.  [Funciones de análisis por
    separado](#8-funciones-de-análisis-por-separado)
9.  [Informe HTML y asistente
    interactivo](#9-informe-html-y-asistente-interactivo)
10. [Datos sintéticos](#10-datos-sintéticos)
11. [Estudio de recuperación (validación del
    método)](#11-estudio-de-recuperación-validación-del-método)
12. [Cómo interpretar los
    resultados](#12-cómo-interpretar-los-resultados)
13. [Cuánto SOV invertir: el método Peckham 1,5
    ampliado](#13-cuánto-sov-invertir-el-método-peckham-15-ampliado)
14. [Referencia de funciones](#14-referencia-de-funciones)
15. [Solución de problemas](#15-solución-de-problemas)
16. [Limitaciones y procedencia de los
    datos](#16-limitaciones-y-procedencia-de-los-datos)
17. [Cita, licencia y
    contribuciones](#17-cita-licencia-y-contribuciones)

------------------------------------------------------------------------

## 1. ¿Qué hace el paquete?

Una marca invierte en publicidad una proporción del total de su
categoría (**SOV**, *share of voice*) y tiene una cuota de ventas
(**SOM**, *share of market*). La diferencia **ESOV = SOV − SOM** (exceso
de cuota de voz, en puntos porcentuales) indica si invierte más o menos
de lo que le correspondería por su tamaño. **mediaSOV** estima, por
categoría, el modelo

$$\mathrm{ESOV}_i = \alpha + \beta\,\mathrm{SOM}_i + \varepsilon_i$$

y responde a la pregunta clásica de la curva de intensidad publicitaria
de Jones (1990): ¿invierten las marcas grandes proporcionalmente menos
que las pequeñas (**β \< 0**)?

| <sub>Módulo</sub> | <sub>Qué ofrece</sub> |
| :--- | :--- |
| <sub>Lectura</sub> | <sub>CSV con separador `;` o `,`, decimal coma o punto, UTF-8 o Latin-1, nombres de columna flexibles</sub> |
| <sub>Análisis</sub> | <sub>MCO, errores robustos HC3, Theil-Sen, validación dejando una marca fuera, influencia (palanca, Cook, DFBETAS), bootstrap de pares, formas funcionales (AICc y validación cruzada), elasticidad log-log, homogeneidad de pendientes</sub> |
| <sub>Salidas</sub> | <sub>Tablas (data.frame o HTML), gráficos, lectura en lenguaje llano, informe HTML autocontenido</sub> |
| <sub>Interfaz</sub> | <sub>Aplicación Shiny (`sov_asistente()`) sin escribir código</sub> |
| <sub>Simulación</sub> | <sub>Datos sintéticos con verdad conocida bajo 5 postulados estáticos y 2 dinámicos, parámetros editables con procedencia, calibración con datos reales y estudio de recuperación</sub> |

## 2. Instalación

### 2.1 Requisitos

- **R ≥ 4.1.0** (<https://cran.r-project.org>). Recomendado: **RStudio**
  (<https://posit.co/download/rstudio-desktop/>), que además incluye
  Pandoc, necesario para el informe HTML.
- Conexión a internet para la instalación.

### 2.2 Instalación desde GitHub (recomendada)

Copie y pegue estas líneas en la consola de R:

``` r
install.packages("remotes")                       # solo la primera vez
remotes::install_github("majesus/mediaSOV")
```

Para instalar también las viñetas (más lento):

``` r
remotes::install_github("majesus/mediaSOV", build_vignettes = TRUE)
```

Paquetes opcionales, necesarios solo para algunas funciones
(`sov_informe()` y `sov_asistente()`):

``` r
install.packages(c("rmarkdown", "knitr", "shiny"))
```

### 2.3 Instalación alternativa sin `remotes`

Descargue el repositorio como ZIP desde GitHub (botón verde *Code* →
*Download ZIP*), descomprímalo y ejecute desde la carpeta que lo
contiene:

``` r
install.packages("ruta/a/mediaSOV-main", repos = NULL, type = "source")
```

### 2.4 Comprobar que funciona

``` r
library(mediaSOV)
packageVersion("mediaSOV")
```

``` r
packageVersion("mediaSOV")
#> [1] '0.1.0'
```

Para actualizar a una versión más reciente, repita la orden de
`install_github()`.

## 3. Inicio rápido (2 minutos)

``` r
library(mediaSOV)
sov_demo()          # recorrido guiado con datos reales y sintéticos
sov_asistente()     # aplicación en el navegador, sin escribir código
```

El mismo análisis en dos pasos:

``` r
x <- sov_analiza(adage2019, B = 300)   # B = remuestras bootstrap (más = más preciso y lento)
sov_tabla(x, "resultados")[, c(1, 2, 3, 4, 11)]
```

| <sub>Categoría</sub> | <sub>n</sub> | <sub>β</sub> | <sub>IC 95 % de β</sub> | <sub>Lectura (MCO)</sub> |
| :--- | ---: | ---: | ---: | :--- |
| <sub>Automoción</sub> | <sub>10</sub> | <sub>−0,35</sub> | <sub>[−0,58; −0,12]</sub> | <sub>Economía de escala</sub> |
| <sub>Restauración</sub> | <sub>10</sub> | <sub>0,07</sub> | <sub>[−1,05; 1,18]</sub> | <sub>No distinguible de 0</sub> |
| <sub>Telefonía móvil</sub> | <sub>6</sub> | <sub>−0,64</sub> | <sub>[−1,25; −0,02]</sub> | <sub>Economía de escala</sub> |
| <sub>Tarjetas de crédito</sub> | <sub>8</sub> | <sub>−0,52</sub> | <sub>[−1,78; 0,74]</sub> | <sub>No distinguible de 0</sub> |
| <sub>Cerveza</sub> | <sub>10</sub> | <sub>−0,05</sub> | <sub>[−0,28; 0,18]</sub> | <sub>No distinguible de 0</sub> |
| <sub>Bebidas</sub> | <sub>10</sub> | <sub>1,19</sub> | <sub>[0,55; 1,84]</sub> | <sub>Deseconomía de escala</sub> |

**Lectura rápida:** 6 categorías y 54 marcas. Automoción y telefonía móvil presentan pendientes negativas cuyo IC clásico excluye cero. La sección 5 contrasta los resultados con HC3.


## 4. Sus propios datos

### 4.1 Formato del archivo

Una fila por marca, con **cuatro columnas obligatorias**:

| <sub>Columna</sub> | <sub>Contenido</sub> | <sub>Variantes de nombre admitidas (ejemplos)</sub> |
| :--- | :--- | :--- |
| <sub>categoría</sub> | <sub>Mercado o sector al que pertenece la marca</sub> | <sub>`categoria`, `sector`, `category`</sub> |
| <sub>marca</sub> | <sub>Nombre de la marca</sub> | <sub>`marca`, `brand`</sub> |
| <sub>SOM</sub> | <sub>Cuota de mercado, **en %** (0–100)</sub> | <sub>`som`, `cuota_mercado`, `market_share`</sub> |
| <sub>SOV</sub> | <sub>Cuota de voz, **en %** (0–100)</sub> | <sub>`sov`, `cuota_voz`, `share_of_voice`</sub> |

Si trabaja con la estructura de Ad Age (columnas `market_share_pct`,
`media_musd`, etc.), el paquete también la reconoce y calcula las cuotas
de voz.

**Reglas que conviene respetar:**

- Cada categoría necesita **al menos 4 marcas**; con menos se omite y el
  paquete lo avisa.
- **No incluya la fila «resto del mercado»**: no es una marca y, como
  las cuotas suman 100 %, fuerza mecánicamente la recta. Solo se incluye
  con `incluir_resto = TRUE` (no recomendado).
- Las cuotas van en **puntos porcentuales** (35, no 0,35). Los valores
  fuera de 0–100 generan un aviso.
- Si sus datos están en Excel (.xlsx), expórtelos antes a CSV (*Archivo
  → Guardar como → CSV*).

### 4.2 Crear una plantilla

``` r
ruta <- sov_plantilla(file.path(tempdir(), "mis_datos.csv"))
#> Archivo creado: /tmp/RtmpfuCrfS/mis_datos.csv
#> Sustituya las cifras ficticias por las suyas (conserve los nombres de columna).
cat(readLines(ruta, n = 8, encoding = "UTF-8"), sep = "\n")
#> categoria;marca;som;sov
#> Categoría ficticia;Marca A;30;26
#> Categoría ficticia;Marca B;22;24
#> Categoría ficticia;Marca C;15;18
#> Categoría ficticia;Marca D;12;10
#> Categoría ficticia;Marca E;8;9
#> Categoría ficticia;Marca F;5;6
```

La plantilla se guarda con separador `;`, coma decimal y marca de orden
de bytes (BOM), de modo que **Excel la abre correctamente** en
configuración regional española. Sustituya las cifras ficticias por las
suyas, **conservando los nombres de columna**, y guárdela como CSV.

Sin argumentos, `sov_plantilla()` crea `plantilla_sov.csv` en el
directorio de trabajo (`getwd()`).

### 4.3 Leer y analizar

``` r
x <- sov_analiza("mis_datos.csv")
```

Si el análisis no se lee como esperaba, inspeccione cómo interpreta el
archivo:

``` r
d <- sov_lee(ruta)       # tabla tal como figura en el archivo
head(d, 3)
#>            categoria   marca som sov
#> 1 Categoría ficticia Marca A  30  26
#> 2 Categoría ficticia Marca B  22  24
#> 3 Categoría ficticia Marca C  15  18
p <- sov_prepara(d)      # datos estandarizados: caso, sector, marca, som, sov, esov...
p
#> <sov_datos> 6 filas, 1 categorías
#>           Categoría Marcas SOM cubierta (%) SOV cubierta (%)
#>  Categoría ficticia      6             92,0             93,0
#> (Cobertura: suma de las cuotas de las marcas incluidas, en %)
```

La salida de `sov_prepara()` resume, por categoría, el número de marcas
y la suma de cuotas cubierta. También admite un `data.frame` ya cargado
en R:

``` r
x <- sov_analiza(mi_data_frame)
```

### 4.4 Datos de ejemplo incluidos

``` r
dim(adage2019)                # 60 filas x 13 columnas (Ad Age, 2019)
#> [1] 60 13
head(adage2019[, c("case_id", "brand", "market_share_pct", "media_musd", "is_rest")])
#>       case_id     brand market_share_pct media_musd is_rest
#> 1 auto_marcas      Ford             14.3        894       0
#> 2 auto_marcas    Toyota             12.3        580       0
#> 3 auto_marcas Chevrolet             12.0        817       0
#> 4 auto_marcas     Honda              8.6        387       0
#> 5 auto_marcas    Nissan              8.4        469       0
#> 6 auto_marcas      Jeep              4.8        290       0
sov_ejemplo()                 # ruta del CSV de ejemplo incluido en el paquete
#> [1] "/usr/local/lib/R/site-library/mediaSOV/extdata/sov_som_casos_adage2019.csv"
```

Se muestran las seis primeras filas y las columnas esenciales (`head()`
oculta el resto): cada fila es una marca de una categoría (`case_id`);
`market_share_pct` es la cuota de mercado en porcentaje de la categoría
y `media_musd` la inversión publicitaria en millones de dólares, de la
que `sov_analiza()` calcula la cuota de voz. La columna `is_rest` vale 1
en la fila «resto del mercado», que se excluye del análisis. Las demás
columnas (`case_title`, `sector`, `pdf_page`, `share_basis`,
`industry_media_total_musd`, `owner`, `focal`, `note`) documentan la
procedencia.

## 5. Análisis: `sov_analiza()` y su lectura

``` r
x <- sov_analiza(datos, nivel = 0.95, B = 2000, semilla = 2019,
                 incluir_resto = FALSE)
```

| <sub>Argumento</sub> | <sub>Significado</sub> |
| :--- | :--- |
| <sub>`datos`</sub> | <sub>Ruta de un CSV, `data.frame` o resultado de `sov_prepara()`/`sov_simula()`</sub> |
| <sub>`nivel`</sub> | <sub>Nivel de confianza de los intervalos (0,95 por defecto)</sub> |
| <sub>`B`</sub> | <sub>Remuestras del bootstrap (2000 por defecto; `0` lo omite y acelera)</sub> |
| <sub>`semilla`</sub> | <sub>Semilla del bootstrap (el generador del usuario se restaura al terminar)</sub> |
| <sub>`incluir_resto`</sub> | <sub>`TRUE` para incluir la fila «resto del mercado» (no recomendado)</sub> |

### 5.1 Resumen

``` r
sov_tabla(x, "resultados")
```

**Estimación e inferencia clásica**

| <sub>Categoría</sub> | <sub>n</sub> | <sub>β</sub> | <sub>IC 95 % de β</sub> | <sub>p</sub> | <sub>R²</sub> | <sub>Lectura (MCO)</sub> |
| :--- | ---: | ---: | ---: | ---: | ---: | :--- |
| <sub>Automoción</sub> | <sub>10</sub> | <sub>−0,35</sub> | <sub>[−0,58; −0,12]</sub> | <sub>0,007</sub> | <sub>0,61</sub> | <sub>Economía de escala</sub> |
| <sub>Restauración</sub> | <sub>10</sub> | <sub>0,07</sub> | <sub>[−1,05; 1,18]</sub> | <sub>0,895</sub> | <sub>0,00</sub> | <sub>No distinguible de 0</sub> |
| <sub>Telefonía móvil</sub> | <sub>6</sub> | <sub>−0,64</sub> | <sub>[−1,25; −0,02]</sub> | <sub>0,045</sub> | <sub>0,68</sub> | <sub>Economía de escala</sub> |
| <sub>Tarjetas de crédito</sub> | <sub>8</sub> | <sub>−0,52</sub> | <sub>[−1,78; 0,74]</sub> | <sub>0,355</sub> | <sub>0,14</sub> | <sub>No distinguible de 0</sub> |
| <sub>Cerveza</sub> | <sub>10</sub> | <sub>−0,05</sub> | <sub>[−0,28; 0,18]</sub> | <sub>0,635</sub> | <sub>0,03</sub> | <sub>No distinguible de 0</sub> |
| <sub>Bebidas</sub> | <sub>10</sub> | <sub>1,19</sub> | <sub>[0,55; 1,84]</sub> | <sub>0,003</sub> | <sub>0,69</sub> | <sub>Deseconomía de escala</sub> |

**Robustez y sensibilidad**

| <sub>Categoría</sub> | <sub>IC 95 % robusto (HC3)</sub> | <sub>β Theil-Sen</sub> | <sub>β al omitir cada marca</sub> | <sub>Umbral SOM</sub> |
| :--- | ---: | ---: | ---: | ---: |
| <sub>Automoción</sub> | <sub>[−0,65; −0,05]</sub> | <sub>−0,50</sub> | <sub>[−0,43; −0,29]</sub> | <sub>3,0 %</sub> |
| <sub>Restauración</sub> | <sub>[−5,17; 5,30]</sub> | <sub>0,12</sub> | <sub>[−2,19; 0,26]</sub> | <sub>—</sub> |
| <sub>Telefonía móvil</sub> | <sub>[−1,26; −0,02]</sub> | <sub>−0,52</sub> | <sub>[−0,80; −0,50]</sub> | <sub>8,8 %</sub> |
| <sub>Tarjetas de crédito</sub> | <sub>[−2,18; 1,15]</sub> | <sub>−0,66</sub> | <sub>[−0,91; −0,07]</sub> | <sub>—</sub> |
| <sub>Cerveza</sub> | <sub>[−0,50; 0,40]</sub> | <sub>0,09</sub> | <sub>[−0,07; 0,14]</sub> | <sub>—</sub> |
| <sub>Bebidas</sub> | <sub>[−0,06; 2,45]</sub> | <sub>1,36</sub> | <sub>[1,15; 1,73]</sub> | <sub>—</sub> |

**Cómo leerlo.** Compare el IC clásico y HC3 antes de concluir. En Bebidas, el intervalo clásico excluye cero, pero el robusto lo incluye.


### 5.2 Lectura en lenguaje llano

`sov_interpreta()` redacta, para cada categoría, qué indican los
coeficientes, cuán robustos son y qué marcas revisar:

``` r
cat(sov_interpreta(x)[1:2], sep = "\n\n")
```
**Automoción** (n = 10 marcas). La pendiente de ESOV sobre SOM es −0,35 (IC 95 %: [−0,58; −0,12]; p = 0,007) y la recta explica el 61 % de la variabilidad (R² = 0,61). Las marcas grandes invierten proporcionalmente menos que las pequeñas (economías de escala, en el sentido de la curva de Jones); el valor de Jones (−0,38) cae dentro del intervalo. Con Theil-Sen la pendiente es −0,50; al omitir cada marca por turno oscila entre −0,43 y −0,29. El ESOV medio se anula cuando la cuota alcanza el 3,0 %: por encima de ese umbral, las marcas invierten de media menos de lo que su cuota sugiere. Marcas con alerta de influencia: Ford (I); Toyota (I); Chevrolet (I). Conviene comprobar que sus datos son correctos y comparar la pendiente sin ellas (columna «beta sin la marca»). En el bootstrap, la pendiente es negativa en el 100 % de las remuestras.

**Restauración** (n = 10 marcas). La pendiente de ESOV sobre SOM es 0,07 (IC 95 %: [−1,05; 1,18]; p = 0,895) y la recta explica el 0 % de la variabilidad (R² = 0,00). La pendiente no se distingue de cero, de modo que el gasto en voz es aproximadamente proporcional a la cuota (SOV ≈ SOM + constante); el valor de Jones (−0,38) cae dentro del intervalo. Con Theil-Sen la pendiente es 0,12; al omitir cada marca por turno oscila entre −2,19 y 0,26, y su signo cambia: el resultado depende de una sola marca y debe tomarse con cautela. Marcas con alerta de influencia: McDonald's (P A I); Starbucks (A). Conviene comprobar que sus datos son correctos y comparar la pendiente sin ellas (columna «beta sin la marca»). En el bootstrap, la pendiente es negativa en el 41 % de las remuestras.


### 5.3 Cómo acceder a los resultados numéricos

El objeto `x` es una lista; cada categoría está en `x$sectores`:

``` r
names(x$sectores)
a <- x$sectores$auto_marcas$ajuste
a[c("n", "alfa", "beta", "ic_beta", "p_beta", "r2", "ts_beta", "ic_beta_hc3")]
```

**Categorías disponibles:** `auto_marcas`, `restaurantes`, `telefonia`, `tarjetas`, `cerveza`, `bebidas`.

| <sub>Campo</sub> | <sub>Valor (sin editar)</sub> |
| :--- | :--- |
| <sub>n</sub> | <sub>10</sub> |
| <sub>alfa</sub> | <sub>1.061521</sub> |
| <sub>beta</sub> | <sub>-0.3498058</sub> |
| <sub>ic_beta</sub> | <sub>-0.5762806 -0.1233310</sub> |
| <sub>p_beta</sub> | <sub>0.007381539</sub> |
| <sub>r2</sub> | <sub>0.6132703</sub> |
| <sub>ts_beta</sub> | <sub>-0.5032545</sub> |
| <sub>ic_beta_hc3</sub> | <sub>-0.64824020 -0.05137132</sub> |


## 6. Tablas

`sov_tabla(x, tipo, categoria, formato)` produce seis tipos de tabla,
como `data.frame` de caracteres con formato español (coma decimal) o
como HTML autocontenido (`formato = "html"`) para pegar en un documento:

| <sub>`tipo`</sub> | <sub>Contenido</sub> |
| :--- | :--- |
| <sub>`"resultados"`</sub> | <sub>β, IC clásico y robusto HC3, p, R², Theil-Sen, rango al omitir cada marca, umbral de SOM</sub> |
| <sub>`"influencia"`</sub> | <sub>Palanca, t\*, Cook, DFBETAS y β sin cada marca, con alertas</sub> |
| <sub>`"formas"`</sub> | <sub>Comparación de formas funcionales (RMSE de validación cruzada, ΔAICc)</sub> |
| <sub>`"bootstrap"`</sub> | <sub>Intervalos bootstrap percentil de MCO y Theil-Sen</sub> |
| <sub>`"elasticidad"`</sub> | <sub>Elasticidad γ del modelo log-log</sub> |
| <sub>`"cobertura"`</sub> | <sub>Cobertura de cuotas de cada categoría</sub> |

``` r
t <- sov_tabla(x, "resultados")
t[, c(1, 2, 3, 4, 6, 7, 11)]
t[, c(1, 5, 8, 9, 10)]
```

**Estimación e inferencia clásica**

| <sub>Categoría</sub> | <sub>n</sub> | <sub>β</sub> | <sub>IC 95 % de β</sub> | <sub>p</sub> | <sub>R²</sub> | <sub>Lectura (MCO)</sub> |
| :--- | ---: | ---: | ---: | ---: | ---: | :--- |
| <sub>Automoción</sub> | <sub>10</sub> | <sub>−0,35</sub> | <sub>[−0,58; −0,12]</sub> | <sub>0,007</sub> | <sub>0,61</sub> | <sub>Economía de escala</sub> |
| <sub>Restauración</sub> | <sub>10</sub> | <sub>0,07</sub> | <sub>[−1,05; 1,18]</sub> | <sub>0,895</sub> | <sub>0,00</sub> | <sub>No distinguible de 0</sub> |
| <sub>Telefonía móvil</sub> | <sub>6</sub> | <sub>−0,64</sub> | <sub>[−1,25; −0,02]</sub> | <sub>0,045</sub> | <sub>0,68</sub> | <sub>Economía de escala</sub> |
| <sub>Tarjetas de crédito</sub> | <sub>8</sub> | <sub>−0,52</sub> | <sub>[−1,78; 0,74]</sub> | <sub>0,355</sub> | <sub>0,14</sub> | <sub>No distinguible de 0</sub> |
| <sub>Cerveza</sub> | <sub>10</sub> | <sub>−0,05</sub> | <sub>[−0,28; 0,18]</sub> | <sub>0,635</sub> | <sub>0,03</sub> | <sub>No distinguible de 0</sub> |
| <sub>Bebidas</sub> | <sub>10</sub> | <sub>1,19</sub> | <sub>[0,55; 1,84]</sub> | <sub>0,003</sub> | <sub>0,69</sub> | <sub>Deseconomía de escala</sub> |

**Robustez y sensibilidad**

| <sub>Categoría</sub> | <sub>IC 95 % robusto (HC3)</sub> | <sub>β Theil-Sen</sub> | <sub>β al omitir cada marca</sub> | <sub>Umbral SOM</sub> |
| :--- | ---: | ---: | ---: | ---: |
| <sub>Automoción</sub> | <sub>[−0,65; −0,05]</sub> | <sub>−0,50</sub> | <sub>[−0,43; −0,29]</sub> | <sub>3,0 %</sub> |
| <sub>Restauración</sub> | <sub>[−5,17; 5,30]</sub> | <sub>0,12</sub> | <sub>[−2,19; 0,26]</sub> | <sub>—</sub> |
| <sub>Telefonía móvil</sub> | <sub>[−1,26; −0,02]</sub> | <sub>−0,52</sub> | <sub>[−0,80; −0,50]</sub> | <sub>8,8 %</sub> |
| <sub>Tarjetas de crédito</sub> | <sub>[−2,18; 1,15]</sub> | <sub>−0,66</sub> | <sub>[−0,91; −0,07]</sub> | <sub>—</sub> |
| <sub>Cerveza</sub> | <sub>[−0,50; 0,40]</sub> | <sub>0,09</sub> | <sub>[−0,07; 0,14]</sub> | <sub>—</sub> |
| <sub>Bebidas</sub> | <sub>[−0,06; 2,45]</sub> | <sub>1,36</sub> | <sub>[1,15; 1,73]</sub> | <sub>—</sub> |


``` r
sov_tabla(x, "influencia", categoria = "restaurantes")
```

**Restauración · cuotas y diagnóstico**

| <sub>Marca</sub> | <sub>SOM (%)</sub> | <sub>SOV (%)</sub> | <sub>ESOV (pp)</sub> | <sub>Alerta</sub> |
| :--- | ---: | ---: | ---: | :--- |
| <sub>McDonald's</sub> | <sub>7,0</sub> | <sub>11,3</sub> | <sub>+4,3</sub> | <sub>P A I</sub> |
| <sub>Starbucks</sub> | <sub>3,3</sub> | <sub>1,2</sub> | <sub>−2,1</sub> | <sub>A</sub> |
| <sub>Subway</sub> | <sub>2,0</sub> | <sub>5,7</sub> | <sub>+3,7</sub> | <sub>—</sub> |
| <sub>Taco Bell</sub> | <sub>1,8</sub> | <sub>6,9</sub> | <sub>+5,1</sub> | <sub>—</sub> |
| <sub>Burger King</sub> | <sub>1,8</sub> | <sub>5,6</sub> | <sub>+3,8</sub> | <sub>—</sub> |
| <sub>Wendy's</sub> | <sub>1,7</sub> | <sub>4,2</sub> | <sub>+2,5</sub> | <sub>—</sub> |
| <sub>Chick-fil-A</sub> | <sub>1,7</sub> | <sub>1,2</sub> | <sub>−0,5</sub> | <sub>—</sub> |
| <sub>Dunkin'</sub> | <sub>1,6</sub> | <sub>2,4</sub> | <sub>+0,8</sub> | <sub>—</sub> |
| <sub>Domino's</sub> | <sub>1,1</sub> | <sub>6,0</sub> | <sub>+4,9</sub> | <sub>—</sub> |
| <sub>Pizza Hut</sub> | <sub>1,0</sub> | <sub>3,4</sub> | <sub>+2,4</sub> | <sub>—</sub> |

**Restauración · influencia y sensibilidad**

| <sub>Marca</sub> | <sub>Palanca</sub> | <sub>t*</sub> | <sub>Cook</sub> | <sub>DFBETAS</sub> | <sub>β sin la marca</sub> |
| :--- | ---: | ---: | ---: | ---: | ---: |
| <sub>McDonald's</sub> | <sub>0,89</sub> | <sub>2,10</sub> | <sub>12,31</sub> | <sub>5,58</sub> | <sub>−2,19</sub> |
| <sub>Starbucks</sub> | <sub>0,14</sub> | <sub>−2,55</sub> | <sub>0,30</sub> | <sub>−0,52</sub> | <sub>0,26</sub> |
| <sub>Subway</sub> | <sub>0,10</sub> | <sub>0,49</sub> | <sub>0,02</sub> | <sub>−0,03</sub> | <sub>0,08</sub> |
| <sub>Taco Bell</sub> | <sub>0,11</sub> | <sub>1,13</sub> | <sub>0,08</sub> | <sub>−0,11</sub> | <sub>0,12</sub> |
| <sub>Burger King</sub> | <sub>0,11</sub> | <sub>0,54</sub> | <sub>0,02</sub> | <sub>−0,05</sub> | <sub>0,09</sub> |
| <sub>Wendy's</sub> | <sub>0,11</sub> | <sub>0,04</sub> | <sub>0,00</sub> | <sub>0,00</sub> | <sub>0,07</sub> |
| <sub>Chick-fil-A</sub> | <sub>0,11</sub> | <sub>−1,28</sub> | <sub>0,10</sub> | <sub>0,15</sub> | <sub>−0,01</sub> |
| <sub>Dunkin'</sub> | <sub>0,12</sub> | <sub>−0,68</sub> | <sub>0,03</sub> | <sub>0,10</sub> | <sub>0,02</sub> |
| <sub>Domino's</sub> | <sub>0,15</sub> | <sub>1,05</sub> | <sub>0,10</sub> | <sub>−0,26</sub> | <sub>0,19</sub> |
| <sub>Pizza Hut</sub> | <sub>0,16</sub> | <sub>−0,02</sub> | <sub>0,00</sub> | <sub>0,00</sub> | <sub>0,06</sub> |

P = palanca alta; A = atípico; I = influyente. — = sin alerta.


``` r
sov_tabla(x, "formas", categoria = "auto_marcas")
```

| <sub>Categoría</sub> | <sub>Forma</sub> | <sub>RMSE CV</sub> | <sub>ΔAICc</sub> | <sub>Mejor en</sub> |
| :--- | :--- | ---: | ---: | :--- |
| <sub>Automoción</sub> | <sub>Lineal</sub> | <sub>1,43</sub> | <sub>0,0</sub> | <sub>—</sub> |
| <sub>Automoción</sub> | <sub>ln SOM</sub> | <sub>1,27</sub> | <sub>−2,3</sub> | <sub>AICc</sub> |
| <sub>Automoción</sub> | <sub>Cuadrática</sub> | <sub>1,21</sub> | <sub>+1,8</sub> | <sub>RMSE</sub> |


``` r
sov_tabla(x, "elasticidad")
```

| <sub>Categoría</sub> | <sub>n</sub> | <sub>γ</sub> | <sub>IC 95 % de γ</sub> | <sub>p (γ = 1)</sub> | <sub>Lectura</sub> |
| :--- | ---: | ---: | ---: | ---: | :--- |
| <sub>Automoción</sub> | <sub>10</sub> | <sub>0,71</sub> | <sub>[0,44; 0,99]</sub> | <sub>0,044</sub> | <sub>Economía de escala</sub> |
| <sub>Restauración</sub> | <sub>10</sub> | <sub>0,28</sub> | <sub>[−0,80; 1,36]</sub> | <sub>0,161</sub> | <sub>No distinguible de 1 (paridad)</sub> |
| <sub>Telefonía móvil</sub> | <sub>6</sub> | <sub>0,93</sub> | <sub>[0,39; 1,47]</sub> | <sub>0,729</sub> | <sub>No distinguible de 1 (paridad)</sub> |
| <sub>Tarjetas de crédito</sub> | <sub>6</sub> | <sub>−0,13</sub> | <sub>[−2,37; 2,11]</sub> | <sub>0,233</sub> | <sub>No distinguible de 1 (paridad)</sub> |
| <sub>Cerveza</sub> | <sub>10</sub> | <sub>1,46</sub> | <sub>[0,64; 2,29]</sub> | <sub>0,231</sub> | <sub>No distinguible de 1 (paridad)</sub> |
| <sub>Bebidas</sub> | <sub>10</sub> | <sub>3,19</sub> | <sub>[0,78; 5,60]</sub> | <sub>0,069</sub> | <sub>No distinguible de 1 (paridad)</sub> |


``` r
sov_tabla(x, "resultados", formato = "html")   # cadena HTML
```

## 7. Gráficos

Gráficos con R base (sin dependencias adicionales). Los datos simulados
llevan automáticamente la marca de agua «DATOS SINTETICOS».

### 7.1 Dispersión por categoría

Recta de mínimos cuadrados con banda de confianza, recta de referencia
de Jones (discontinua) y marcas con alerta de influencia en rojo:

``` r
sov_grafico(x, "auto_marcas")
```

<img src="man/figures/README-graf1-1.png" width="90%" />

``` r
sov_grafico(x, "restaurantes")
```

<img src="man/figures/README-graf2-1.png" width="90%" />

`sov_grafico(x)` sin categoría dibuja todas; `etiquetas = FALSE` suprime
los nombres de marca.

### 7.2 Resumen de todas las categorías

``` r
sov_grafico_bosque(x)
```

<img src="man/figures/README-graf3-1.png" width="90%" />

### 7.3 Gráfico de método genérico

``` r
plot(x)    # equivale a sov_grafico(x)
```

### 7.4 Guardar un gráfico

``` r
png("auto.png", width = 1400, height = 900, res = 200)
sov_grafico(x, "auto_marcas")
dev.off()
```

### 7.5 Mapa SOV–SOM: `sov_mapa()`

``` r
sov_mapa(adage2019, "auto_marcas", marca = "Chevrolet")
```

<img src="man/figures/README-mapa-1.png" width="90%" />

Cada punto es una marca (SOV en abscisas, SOM en ordenadas). La diagonal
es el equilibrio SOV = SOM (ESOV = 0): por encima, zona de cosecha; por
debajo, zona de inversión. La línea roja discontinua es la aproximación
lineal a la curva de Jones (1990), ESOV = α + β·SOM, trasladada a este
plano como SOV = α + (1 + β)·SOM; se desactiva con `jones = FALSE`. Sus valores son α = +6,4 y β = −0,38.

## 8. Funciones de análisis por separado

Cada pieza se puede usar de forma independiente con vectores numéricos.
En los ejemplos, `som`, `sov` y `esov` son de la categoría Automoción.

``` r
z <- x$sectores$auto_marcas$datos
som <- z$som; sov <- z$sov; esov <- z$esov; marca <- z$marca
```

**Ajuste por mínimos cuadrados con errores robustos y Theil-Sen**
(`sov_ajusta`):

``` r
a <- sov_ajusta(som, esov)
```

| <sub>Método</sub> | <sub>β</sub> | <sub>EE</sub> | <sub>p</sub> | <sub>IC 95 %</sub> |
| :--- | ---: | ---: | ---: | ---: |
| <sub>MCO</sub> | <sub>−0,3498</sub> | <sub>0,0982</sub> | <sub>0,0074</sub> | <sub>[−0,5763; −0,1233]</sub> |
| <sub>MCO + HC3</sub> | <sub>−0,3498</sub> | <sub>0,1294</sub> | <sub>0,0270</sub> | <sub>[−0,6482; −0,0514]</sub> |


**Estimador de Theil-Sen** (mediana de las pendientes por pares; poco
sensible a extremos):

``` r
sov_theil_sen(som, esov)
```

| <sub>Intercepto α</sub> | <sub>Pendiente β</sub> |
| ---: | ---: |
| <sub>1,7181</sub> | <sub>−0,5033</sub> |


**Influencia** (palanca, t\* estudentizado, Cook, DFBETAS, β al omitir
la marca):

``` r
i <- sov_influencia(som, esov, marca, sov)
```

| <sub>Marca</sub> | <sub>SOM (%)</sub> | <sub>SOV (%)</sub> | <sub>ESOV (pp)</sub> | <sub>Residuo</sub> |
| :--- | ---: | ---: | ---: | ---: |
| <sub>Ford</sub> | <sub>14,30</sub> | <sub>11,49</sub> | <sub>−2,81</sub> | <sub>1,13</sub> |
| <sub>Toyota</sub> | <sub>12,30</sub> | <sub>7,45</sub> | <sub>−4,85</sub> | <sub>−1,61</sub> |
| <sub>Chevrolet</sub> | <sub>12,00</sub> | <sub>10,50</sub> | <sub>−1,50</sub> | <sub>1,63</sub> |
| <sub>Honda</sub> | <sub>8,60</sub> | <sub>4,97</sub> | <sub>−3,63</sub> | <sub>−1,68</sub> |
| <sub>Nissan</sub> | <sub>8,40</sub> | <sub>6,03</sub> | <sub>−2,37</sub> | <sub>−0,50</sub> |
| <sub>Jeep</sub> | <sub>4,80</sub> | <sub>3,73</sub> | <sub>−1,07</sub> | <sub>−0,46</sub> |
| <sub>Hyundai</sub> | <sub>3,90</sub> | <sub>3,30</sub> | <sub>−0,60</sub> | <sub>−0,30</sub> |
| <sub>Subaru</sub> | <sub>3,80</sub> | <sub>3,62</sub> | <sub>−0,18</sub> | <sub>0,09</sub> |
| <sub>Kia</sub> | <sub>3,40</sub> | <sub>4,83</sub> | <sub>1,43</sub> | <sub>1,56</sub> |
| <sub>GMC</sub> | <sub>3,30</sub> | <sub>3,34</sub> | <sub>0,04</sub> | <sub>0,13</sub> |


| <sub>Marca</sub> | <sub>Palanca</sub> | <sub>t*</sub> | <sub>Cook</sub> | <sub>DFBETAS</sub> | <sub>β sin marca</sub> | <sub>Alerta</sub> |
| :--- | ---: | ---: | ---: | ---: | ---: | :--- |
| <sub>Ford</sub> | <sub>0,391</sub> | <sub>1,191</sub> | <sub>0,433</sub> | <sub>0,823</sub> | <sub>−0,429</sub> | <sub>I</sub> |
| <sub>Toyota</sub> | <sub>0,245</sub> | <sub>−1,640</sub> | <sub>0,361</sub> | <sub>−0,719</sub> | <sub>−0,286</sub> | <sub>I</sub> |
| <sub>Chevrolet</sub> | <sub>0,228</sub> | <sub>1,648</sub> | <sub>0,330</sub> | <sub>0,670</sub> | <sub>−0,410</sub> | <sub>I</sub> |
| <sub>Honda</sub> | <sub>0,108</sub> | <sub>−1,555</sub> | <sub>0,124</sub> | <sub>−0,146</sub> | <sub>−0,337</sub> | <sub>—</sub> |
| <sub>Nissan</sub> | <sub>0,105</sub> | <sub>−0,401</sub> | <sub>0,011</sub> | <sub>−0,031</sub> | <sub>−0,347</sub> | <sub>—</sub> |
| <sub>Jeep</sub> | <sub>0,145</sub> | <sub>−0,376</sub> | <sub>0,013</sub> | <sub>0,086</sub> | <sub>−0,359</sub> | <sub>—</sub> |
| <sub>Hyundai</sub> | <sub>0,180</sub> | <sub>−0,247</sub> | <sub>0,008</sub> | <sub>0,077</sub> | <sub>−0,358</sub> | <sub>—</sub> |
| <sub>Subaru</sub> | <sub>0,185</sub> | <sub>0,076</sub> | <sub>0,001</sub> | <sub>−0,024</sub> | <sub>−0,347</sub> | <sub>—</sub> |
| <sub>Kia</sub> | <sub>0,204</sub> | <sub>1,516</sub> | <sub>0,254</sub> | <sub>−0,548</sub> | <sub>−0,300</sub> | <sub>—</sub> |
| <sub>GMC</sub> | <sub>0,209</sub> | <sub>0,113</sub> | <sub>0,002</sub> | <sub>−0,042</sub> | <sub>−0,345</sub> | <sub>—</sub> |


**Bootstrap de pares** (no supone normalidad):

``` r
b <- sov_bootstrap(som, esov, B = 500, semilla = 1)
```

| <sub>Método</sub> | <sub>IC 95 % percentil</sub> |
| :--- | ---: |
| <sub>MCO</sub> | <sub>[−0,6992; −0,1903]</sub> |
| <sub>Theil-Sen</sub> | <sub>[−0,7431; −0,2242]</sub> |


**Formas funcionales alternativas** (lineal, ln SOM, cuadrática), con
RMSE de validación cruzada dejando una marca fuera (PRESS) y AICc:

``` r
sov_formas(som, esov)
```

| <sub>Forma</sub> | <sub>k</sub> | <sub>RMSE CV</sub> | <sub>AICc</sub> | <sub>ΔAICc</sub> | <sub>Mejor RMSE</sub> | <sub>Mejor AICc</sub> |
| :--- | ---: | ---: | ---: | ---: | :--- | :--- |
| <sub>Lineal</sub> | <sub>3</sub> | <sub>1,43</sub> | <sub>40,48</sub> | <sub>0,00</sub> | <sub>—</sub> | <sub>—</sub> |
| <sub>ln SOM</sub> | <sub>3</sub> | <sub>1,27</sub> | <sub>38,14</sub> | <sub>−2,35</sub> | <sub>—</sub> | <sub>Sí</sub> |
| <sub>Cuadrática</sub> | <sub>4</sub> | <sub>1,21</sub> | <sub>42,27</sub> | <sub>1,79</sub> | <sub>Sí</sub> | <sub>—</sub> |


**Elasticidad** (modelo log-log, SOV = c · SOM<sup>γ</sup>; γ \< 1
indica economías de escala):

``` r
sov_elasticidad(som, sov)
```

| <sub>Indicador</sub> | <sub>Valor</sub> |
| :--- | :--- |
| <sub>n</sub> | <sub>10</sub> |
| <sub>gamma</sub> | <sub>0,7131474</sub> |
| <sub>se</sub> | <sub>0,1202583</sub> |
| <sub>ic</sub> | <sub>0,4358312; 0,9904635</sub> |
| <sub>p_igual1</sub> | <sub>0,04417841</sub> |
| <sub>excluidas</sub> | <sub>0</sub> |


**Homogeneidad de pendientes** entre categorías (contraste F de
pendientes comunes):

``` r
sov_heterogeneidad(x$datos)
```

| <sub>Indicador</sub> | <sub>Valor</sub> |
| :--- | ---: |
| <sub>F</sub> | <sub>3,372421</sub> |
| <sub>gl1</sub> | <sub>5</sub> |
| <sub>gl2</sub> | <sub>42</sub> |
| <sub>p</sub> | <sub>0,01191121</sub> |
| <sub>beta_comun</sub> | <sub>−0,2473603</sub> |
| <sub>n</sub> | <sub>54</sub> |
| <sub>casos</sub> | <sub>6</sub> |


## 9. Informe HTML y asistente interactivo

### 9.1 Informe

``` r
sov_informe(x, archivo = "informe.html", titulo = "Mi informe", autor = "Su nombre")

# Con la marca y la categoría que se quieren seguir en la guía 1
sov_informe(adage2019, archivo = "informe.html",
            categoria = "auto_marcas", marca = "Chevrolet",
            epsilon = 0.05, anios = 3, inversion = 50)
```

Genera un HTML autocontenido (se puede enviar por correo) con resumen,
**dos guías paso a paso** (véase 9.2), lectura en lenguaje llano,
tablas, gráficos, diagnóstico de influencia, formas funcionales,
elasticidad, glosario, limitaciones y referencias. Si los datos son
sintéticos, el informe lo indica en un recuadro destacado e incluye el
postulado, los parámetros y su procedencia. Requiere `rmarkdown`,
`knitr` y Pandoc (incluido en RStudio).

### 9.2 Guías paso a paso: `sov_guia()`

Las guías están pensadas para estudiantes y para quien no es experto:
acompañan la lectura de los datos con un tono didáctico, una pregunta
por paso y un recuadro con el resultado. Todas las cifras, las figuras y
las advertencias se generan a partir de **sus** datos, de modo que el
texto cambia cuando cambia el resultado (por ejemplo, si una sola marca
decide el signo de la pendiente).

``` r
x <- sov_analiza(adage2019)

# Guía 1 (10 pasos): ¿invierte esta marca lo que cabría esperar de una marca de su tamaño?
sov_guia(x, "marca", categoria = "auto_marcas", marca = "Chevrolet")

# Guía 2 (11 pasos): ¿podemos fiarnos de la recta calculada con pocas marcas?
sov_guia(x, "sector", categoria = "auto_marcas")

# Página HTML independiente, o versión en texto plano
sov_guia(x, "marca", "auto_marcas", "Chevrolet", archivo = "guia_chevrolet.html")
sov_guia(x, "sector", "auto_marcas", formato = "texto")
```

La guía 1 recorre SOM, SOV, ESOV, el mapa, la referencia de Jones, una
segunda referencia (la regresión de la propia categoría), la proyección
con la elasticidad ε y la palanca de inversión. La guía 2 recorre la
nube de puntos, la recta, la lectura de α y β, la confianza (error
estándar, intervalo, HC3, bootstrap), la comparación entre categorías,
el análisis dejando fuera una marca cada vez, los diagnósticos de
influencia, Theil-Sen y recta frente a curva. Las guías recuerdan que ε = 0,05 es un supuesto operativo, no una estimación, y señalan con un recuadro los datos sintéticos.

### 9.3 Asistente sin código

``` r
sov_asistente()
```

Abre en el navegador una aplicación con tres orígenes de datos (ejemplo
real, CSV propio con descarga de plantilla, o datos sintéticos),
selector de nivel de confianza y bootstrap, pestañas de lectura,
resultados, gráfico, influencia, guía paso a paso, glosario y ayuda, y
descarga del informe HTML. Requiere `shiny`.

### 9.4 Glosario

``` r
sov_glosario("beta")
```

| <sub>Término</sub> | <sub>Definición</sub> |
| :--- | :--- |
| <sub>beta (pendiente)</sub> | <sub>Cambio medio del ESOV por cada punto porcentual adicional de SOM. Negativo: las marcas grandes invierten proporcionalmente menos.</sub> |
| <sub>Distancia de Cook / DFBETAS</sub> | <sub>Medidas de cuánto cambia la pendiente si se omite una marca.</sub> |


## 10. Datos sintéticos

> **Los datos sintéticos no son evidencia empírica.** Sirven para (i)
> comprobar que un método recupera una verdad conocida bajo un supuesto
> explícito y (ii) reproducir órdenes de magnitud calibrados con datos
> publicados. Nunca para afirmar nada sobre un mercado real.

### 10.1 Postulados disponibles

``` r
sov_postulados()[, c("id", "nombre", "tipo", "formulacion")]
```

| <sub>ID</sub> | <sub>Postulado</sub> | <sub>Tipo</sub> | <sub>Formulación</sub> |
| :--- | :--- | :--- | :--- |
| <sub>jones_lineal</sub> | <sub>Curva de Jones (lineal)</sub> | <sub>estático</sub> | <sub>ESOV = beta (SOM - media): las marcas pequeñas invierten proporcionalmente más si beta < 0</sub> |
| <sub>paridad</sub> | <sub>Paridad (SOV = SOM)</sub> | <sub>estático</sub> | <sub>ESOV = 0 salvo ruido: cada marca invierte en proporción a su cuota</sub> |
| <sub>jones_heterogeneo</sub> | <sub>Curva de Jones heterogénea por categoría</sub> | <sub>estático</sub> | <sub>Como jones_lineal, con beta_c ~ N(beta, tau^2) distinto en cada categoría</sub> |
| <sub>potencia</sub> | <sub>Ley de potencia</sub> | <sub>estático</sub> | <sub>SOV proporcional a SOM^gamma: gamma < 1 economías de escala, gamma > 1 deseconomías</sub> |
| <sub>curvilinea</sub> | <sub>Curvilínea (ESOV cuadrático)</sub> | <sub>estático</sub> | <sub>ESOV = beta z + delta (z^2 - media(z^2)), z = SOM - media: efecto no lineal de la cuota</sub> |
| <sub>equilibrio</sub> | <sub>Equilibrio de cuotas</sub> | <sub>dinámico</sub> | <sub>d ln SOM = eta ln(SOV/SOM) + u con eta = 0: el exceso de voz no cambia la cuota</sub> |
| <sub>elasticidad</sub> | <sub>Elasticidad de largo plazo</sub> | <sub>dinámico</sub> | <sub>d ln SOM = eta ln(SOV/SOM) + u con eta > 0: el exceso de voz hace crecer la cuota</sub> |


### 10.2 Generar datos

``` r
s <- sov_simula("jones_lineal", semilla = 2019)
s
```

**Datos sintéticos:** 66 filas, 6 categorías. Se excluye la fila «resto del mercado» de cada categoría.

| <sub>Categoría</sub> | <sub>Marcas</sub> | <sub>SOM cubierta (%)</sub> | <sub>SOV cubierta (%)</sub> |
| :--- | ---: | ---: | ---: |
| <sub>Categoría 1</sub> | <sub>10</sub> | <sub>79,0</sub> | <sub>59,3</sub> |
| <sub>Categoría 2</sub> | <sub>10</sub> | <sub>63,0</sub> | <sub>51,5</sub> |
| <sub>Categoría 3</sub> | <sub>10</sub> | <sub>66,0</sub> | <sub>45,8</sub> |
| <sub>Categoría 4</sub> | <sub>10</sub> | <sub>61,8</sub> | <sub>35,4</sub> |
| <sub>Categoría 5</sub> | <sub>10</sub> | <sub>64,5</sub> | <sub>51,7</sub> |
| <sub>Categoría 6</sub> | <sub>10</sub> | <sub>65,6</sub> | <sub>60,2</sub> |


Cada categoría tiene cuotas que suman exactamente 100 % (mercado
cerrado) y el SOV se genera con ruido de Dirichlet (Morais et al.,
2017), que preserva el cierre sin sesgo en la media. La **verdad
conocida** está en el atributo `simulacion`:

``` r
sim <- attr(s, "simulacion")
sim$verdad[, c("caso", "beta_lineal_publicadas", "cobertura_som")]
```

Postulado: `jones_lineal`. Semilla: 2019.

| <sub>Caso</sub> | <sub>β verdadera</sub> | <sub>SOM cubierta (%)</sub> |
| :--- | ---: | ---: |
| <sub>cat01</sub> | <sub>−0,38</sub> | <sub>79,03</sub> |
| <sub>cat02</sub> | <sub>−0,38</sub> | <sub>63,03</sub> |
| <sub>cat03</sub> | <sub>−0,38</sub> | <sub>65,96</sub> |
| <sub>cat04</sub> | <sub>−0,38</sub> | <sub>61,79</sub> |
| <sub>cat05</sub> | <sub>−0,38</sub> | <sub>64,47</sub> |
| <sub>cat06</sub> | <sub>−0,38</sub> | <sub>65,58</sub> |


Se analizan con las mismas funciones que los datos reales, y todo
resultado derivado se rotula como sintético:

``` r
xs <- sov_analiza(s, B = 0)
sov_tabla(xs, "resultados")[, 1:5]
```

**Datos sintéticos.**

| <sub>Categoría</sub> | <sub>n</sub> | <sub>β</sub> | <sub>IC 95 %</sub> | <sub>IC robusto HC3</sub> |
| :--- | ---: | ---: | ---: | ---: |
| <sub>Categoría 1</sub> | <sub>10</sub> | <sub>−0,44</sub> | <sub>[−0,67; −0,20]</sub> | <sub>[−0,70; −0,18]</sub> |
| <sub>Categoría 2</sub> | <sub>10</sub> | <sub>−0,23</sub> | <sub>[−0,72; 0,26]</sub> | <sub>[−1,03; 0,58]</sub> |
| <sub>Categoría 3</sub> | <sub>10</sub> | <sub>−0,86</sub> | <sub>[−1,44; −0,29]</sub> | <sub>[−1,13; −0,60]</sub> |
| <sub>Categoría 4</sub> | <sub>10</sub> | <sub>−0,61</sub> | <sub>[−0,99; −0,23]</sub> | <sub>[−1,53; 0,31]</sub> |
| <sub>Categoría 5</sub> | <sub>10</sub> | <sub>−0,11</sub> | <sub>[−0,66; 0,44]</sub> | <sub>[−1,27; 1,04]</sub> |
| <sub>Categoría 6</sub> | <sub>10</sub> | <sub>−1,07</sub> | <sub>[−1,75; −0,39]</sub> | <sub>[−1,49; −0,65]</sub> |


La misma semilla reproduce exactamente los mismos datos; el generador de
números aleatorios del usuario no se altera.

### 10.3 Parámetros y su procedencia

``` r
p <- sov_parametros("jones_lineal")
p$procedencia
```

| <sub>Parámetro</sub> | <sub>Valor</sub> | <sub>Procedencia</sub> |
| :--- | :--- | :--- |
| <sub>n_categorias</sub> | <sub>6</sub> | <sub>Supuesto por defecto (igual al número de casos de AdAge 2019)</sub> |
| <sub>n_total_marcas</sub> | <sub>30</sub> | <sub>Supuesto por defecto (Ad Age solo publica las marcas líderes)</sub> |
| <sub>n_publicadas</sub> | <sub>10</sub> | <sub>Calibrado con AdAge 2019 (6 categorías)</sub> |
| <sub>resto</sub> | <sub>TRUE</sub> | <sub>Estructura de Ad Age (fila derivada)</sub> |
| <sub>theta</sub> | <sub>0,8334</sub> | <sub>Calibrado con AdAge 2019 (6 categorías); forma de ley de potencia: Bae et al. (2024)</sub> |
| <sub>theta_sd</sub> | <sub>0,5014</sub> | <sub>Calibrado con AdAge 2019 (6 categorías) (dispersión entre categorías)</sub> |
| <sub>sigma_forma</sub> | <sub>0,2396</sub> | <sub>Calibrado con AdAge 2019 (6 categorías)</sub> |
| <sub>kappa</sub> | <sub>43,2761</sub> | <sub>Calibrado con AdAge 2019 (6 categorías) (precisión de Dirichlet, estimador de momentos); distribución de cuotas: Morais et al. (2017)</sub> |
| <sub>beta</sub> | <sub>−0,38</sub> | <sub>Ajuste lineal a la tabla de Jones (1990)</sub> |
| <sub>tau_beta</sub> | <sub>0</sub> | <sub>Supuesto por defecto (sin heterogeneidad)</sub> |
| <sub>gamma</sub> | <sub>0,8205</sub> | <sub>Calibrado con AdAge 2019 (6 categorías) (mediana de la elasticidad log-log)</sub> |
| <sub>tau_gamma</sub> | <sub>0</sub> | <sub>Supuesto por defecto (sin heterogeneidad)</sub> |
| <sub>delta</sub> | <sub>0,004</sub> | <sub>Supuesto de sensibilidad (sin respaldo empírico)</sub> |


Cada parámetro indica su valor, su procedencia (calibración con Ad Age
2019, valor de la literatura, supuesto operativo o valor del usuario) y
la fuente. Se modifican por nombre:

``` r
s2 <- sov_simula("jones_lineal", semilla = 1, beta = -0.5, kappa = 300, n_categorias = 12)
```

Los parámetros modificados quedan registrados como procedencia
«usuario». También se puede construir el objeto de parámetros primero y
reutilizarlo:

``` r
p <- sov_parametros("jones_lineal", beta = -0.5)
s3 <- sov_simula("jones_lineal", parametros = p, semilla = 2)
```

Todos los postulados estáticos se generan igual cambiando el
identificador: `"paridad"`, `"jones_heterogeneo"`, `"potencia"`,
`"curvilinea"`.

### 10.4 Calibración con los datos reales

``` r
cal <- sov_calibra()
cal$por_caso
cal$resumen
```

| <sub>Categoría</sub> | <sub>n</sub> | <sub>θ</sub> | <sub>σ forma</sub> | <sub>γ</sub> | <sub>κ</sub> | <sub>β</sub> | <sub>EE β</sub> |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| <sub>Automoción</sub> | <sub>10</sub> | <sub>0,738</sub> | <sub>0,233</sub> | <sub>0,713</sub> | <sub>374,867</sub> | <sub>−0,350</sub> | <sub>0,098</sub> |
| <sub>Restauración</sub> | <sub>10</sub> | <sub>0,724</sub> | <sub>0,173</sub> | <sub>0,279</sub> | <sub>68,371</sub> | <sub>0,066</sub> | <sub>0,483</sub> |
| <sub>Telefonía móvil</sub> | <sub>6</sub> | <sub>1,582</sub> | <sub>0,724</sub> | <sub>0,928</sub> | <sub>20,418</sub> | <sub>−0,636</sub> | <sub>0,220</sub> |
| <sub>Tarjetas de crédito</sub> | <sub>8</sub> | <sub>0,929</sub> | <sub>0,279</sub> | <sub>−0,134</sub> | <sub>8,285</sub> | <sub>−0,517</sub> | <sub>0,515</sub> |
| <sub>Cerveza</sub> | <sub>10</sub> | <sub>1,845</sub> | <sub>0,246</sub> | <sub>1,465</sub> | <sub>30,583</sub> | <sub>−0,049</sub> | <sub>0,098</sub> |
| <sub>Bebidas</sub> | <sub>10</sub> | <sub>0,688</sub> | <sub>0,132</sub> | <sub>3,194</sub> | <sub>55,969</sub> | <sub>1,195</sub> | <sub>0,280</sub> |

Resumen (medianas entre categorías): theta = 0.833 (sd 0.501), sigma_forma = 0.24, gamma = 0.82, kappa = 43.3, beta = -0.199, tau_beta = 0.579


Estima, por método de momentos y por categoría, el tamaño del mercado
(`theta`), la dispersión de las cuotas, la elasticidad `gamma`, la
precisión del ruido (`kappa`) y la pendiente `beta`. Admite sus propios
datos: `sov_calibra(sus_datos)`, y
`sov_parametros("jones_lineal", calibrar_con = sus_datos)` los usa
directamente.

### 10.5 Simulación dinámica (panel temporal)

Para estudiar si el exceso de voz hace crecer la cuota de mercado en el
tiempo:

``` r
d <- sov_simula_dinamica("elasticidad", semilla = 11)
head(d[, c("marca", "periodo", "som", "sov", "esov")])
sov_efecto_esov(d)
```

**Datos sintéticos:** 528 filas, 6 categorías, 8 períodos.

| <sub>Marca</sub> | <sub>Período</sub> | <sub>SOM (%)</sub> | <sub>SOV (%)</sub> | <sub>ESOV (pp)</sub> |
| :--- | ---: | ---: | ---: | ---: |
| <sub>Marca 01</sub> | <sub>1</sub> | <sub>12,06</sub> | <sub>18,33</sub> | <sub>6,26</sub> |
| <sub>Marca 02</sub> | <sub>1</sub> | <sub>7,55</sub> | <sub>4,25</sub> | <sub>−3,30</sub> |
| <sub>Marca 03</sub> | <sub>1</sub> | <sub>6,29</sub> | <sub>10,24</sub> | <sub>3,95</sub> |
| <sub>Marca 04</sub> | <sub>1</sub> | <sub>5,74</sub> | <sub>2,14</sub> | <sub>−3,61</sub> |
| <sub>Marca 05</sub> | <sub>1</sub> | <sub>4,90</sub> | <sub>1,43</sub> | <sub>−3,46</sub> |
| <sub>Marca 06</sub> | <sub>1</sub> | <sub>4,79</sub> | <sub>3,18</sub> | <sub>−1,61</sub> |

| <sub>Indicador</sub> | <sub>Valor</sub> |
| :--- | :--- |
| <sub>eta</sub> | <sub>0,2395361</sub> |
| <sub>se</sub> | <sub>0,001589648</sub> |
| <sub>ic</sub> | <sub>0,2364104; 0,2426618</sub> |
| <sub>p</sub> | <sub>0</sub> |
| <sub>n</sub> | <sub>420</sub> |
| <sub>grupos</sub> | <sub>42</sub> |
| <sub>gl</sub> | <sub>377</sub> |


Con `"equilibrio"` (η = 0, Graham, 2009) el efecto estimado debe ser
nulo; con `"elasticidad"` (η = 0,24) debe aproximarse a ese valor. La
elasticidad 0,24 es un **supuesto operativo** inspirado en Sethuraman et
al. (2011), no una estimación propia.

## 11. Estudio de recuperación (validación del método)

`sov_valida_simulacion()` repite la simulación `R` veces y mide el
sesgo, el error cuadrático y la **cobertura** de los intervalos (cuántas
veces contienen el valor verdadero):

``` r
sov_valida_simulacion("jones_lineal", R = 500, B = 500, semilla = 11)
```

``` r
v <- sov_valida_simulacion("jones_lineal", R = 100, semilla = 11, B = 200)
v$resumen
```

| <sub>Medida</sub> | <sub>Valor</sub> | <sub>Error Monte Carlo</sub> |
| :--- | ---: | ---: |
| <sub>Sesgo medio de beta (MCO)</sub> | <sub>0,0028</sub> | <sub>0,0317</sub> |
| <sub>RMSE de beta (MCO)</sub> | <sub>0,7746</sub> | <sub>NA</sub> |
| <sub>Cobertura del IC 95 % de beta (MCO clásico)</sub> | <sub>0,8550</sub> | <sub>0,0144</sub> |
| <sub>Tasa de rechazo de beta = 0 (MCO clásico, p < 0,05)</sub> | <sub>0,4450</sub> | <sub>0,0203</sub> |
| <sub>Cobertura del IC 95 % de beta (robusto HC3)</sub> | <sub>0,9217</sub> | <sub>0,0110</sub> |
| <sub>Tasa de rechazo de beta = 0 (HC3, p < 0,05)</sub> | <sub>0,2283</sub> | <sub>0,0171</sub> |
| <sub>Sesgo medio de beta (Theil-Sen)</sub> | <sub>0,0129</sub> | <sub>0,0364</sub> |
| <sub>RMSE de beta (Theil-Sen)</sub> | <sub>0,8902</sub> | <sub>NA</sub> |
| <sub>Cobertura del IC 95 % de beta (bootstrap percentil, B = 200)</sub> | <sub>0,8917</sub> | <sub>0,0127</sub> |

Forma funcional elegida por AICc: Lineal 58.3 % | ln SOM 32.2 % | Cuadrática 9.5 %


Una cobertura cercana al 95 % indica que los intervalos son fiables bajo
ese postulado. Los resultados dependen de `R`, de la semilla y de los
parámetros; el `error_mc` es la incertidumbre de Monte Carlo. Con `R`
pequeño (como en este ejemplo) las cifras son aproximadas; para
resultados citables use `R ≥ 500`.

**Lectura de este resultado.** El estimador de la pendiente es
prácticamente insesgado, pero el intervalo **clásico** de MCO cubre
menos del 95 % nominal con 6–10 marcas por categoría, mientras que el
intervalo robusto HC3 y el bootstrap se aproximan más. Por eso el
paquete muestra siempre ambos intervalos.

## 12. Cómo interpretar los resultados

- **β \< 0 con IC que excluye 0**: las marcas grandes invierten
  proporcionalmente menos (economías de escala en el sentido de Jones).
  **β \> 0**: lo contrario. **IC que contiene 0**: el gasto es
  aproximadamente proporcional a la cuota.
- Como SOM figura en ambos lados de la ecuación, β se interpreta frente
  a SOV = SOM (β = 0), **no frente a 0 en SOV**.
- **Robustez**: compare el IC clásico con el HC3, Theil-Sen y el
  bootstrap. Si el signo cambia al omitir una marca (columna «β al
  omitir cada marca»), el resultado depende de esa marca y debe tomarse
  con cautela.
- **Umbral de SOM**: cuota en la que el ESOV medio se anula; por encima,
  las marcas invierten de media menos de lo que su cuota sugiere.
- **Alertas de influencia**: P = palanca alta; A = residuo atípico; I =
  influencia sobre la pendiente (Cook o DFBETAS). Son umbrales
  heurísticos: revise los datos de esas marcas antes de decidir.
- **Formas funcionales**: si la forma lineal no es la mejor por RMSE y
  AICc, la relación puede no ser lineal.
- Una asociación entre ESOV y SOM **no demuestra causalidad**.

## 13. Cuánto SOV invertir: el método Peckham 1,5 ampliado

Los apartados anteriores diagnostican dónde está una marca. Este responde a la pregunta que sigue al diagnóstico: **qué cuota de voz debe sostener durante los próximos dos años para alcanzar una cuota de mercado objetivo**, cuánto presupuesto supone y cómo se desplazará la marca en el mapa ESOV–SOM (el de la recta de Jones, `sov_grafico()`) y en el mapa SOV–SOM (`sov_mapa()`). El punto de partida es la regla del 1,5; el resultado es una fórmula que la contiene como caso particular y que incorpora lo que esa regla no considera.

### 13.1 La regla de partida y sus tres silencios

El método parte de una regla simple para lanzamientos: una marca nueva que aspira a una cuota de mercado $s^\ast$ sostiene durante dos años una cuota de voz de $1{,}5\,s^\ast$. Danenberg et al. (2016) sitúan en los trabajos de Peckham de los años setenta el arranque del uso de la relación entre SOV y SOM como criterio presupuestario, y emparentan su propio análisis longitudinal con la «diferencia dinámica» que Peckham propuso (pp. 139, 141).

La regla debe su difusión a que comprime una decisión compleja en un solo número. Esa compresión tiene un precio: guarda silencio sobre tres variables que alteran la respuesta.

**El punto de partida.** La regla prescribe lo mismo a una marca que nace que a otra que ya posee el 8 % y desea el 10 %; la cuota actual no interviene en el cálculo.

**El tamaño de la marca.** El equilibrio implícito es SOV = SOM. La curva de intensidad publicitaria de Jones (1990) describe otra cosa: las marcas pequeñas necesitan voz por encima de su cuota solo para conservarla, y las grandes se sostienen por debajo. Danenberg et al. (2016) observan esa forma descendente en bebidas refrescantes y en proveedores de internet de once países, también en medios distintos de la televisión, si bien la pendiente y el intercepto cambian entre categorías, países y años, de modo que no existe una recta universal (pp. 142, 144).

**La velocidad de respuesta.** La regla no indica con qué rapidez responde la cuota al exceso de voz. El documento aporta un orden de magnitud para bienes de consumo envasado: alrededor de medio punto de cuota al año por cada 10 puntos de ESOV, con el ESOV medido frente a SOV = SOM (Field, 2009, citado en Danenberg et al., 2016, p. 140).

### 13.2 El modelo: la cuota persigue a la voz

Sea $s(t)$ la cuota de mercado de la marca, en %, y $v$ la cuota de voz que sostiene. El modelo supone que la cuota crece en proporción a la distancia entre la voz comprada y la voz que su tamaño exige:

$$\frac{ds}{dt} \;=\; k\,\bigl[\,v - v^{\ast}(s)\,\bigr], \qquad v^{\ast}(s) \;=\; \alpha + (1+\beta)\,s .$$

El término $v^{\ast}(s)$ es la **SOV de mantenimiento**: la voz con la que una marca de cuota $s$ ni gana ni pierde. Procede de la misma recta que estima `sov_analiza()`, ESOV = α + β·SOM, trasladada al plano SOV–SOM como hace `sov_mapa()`. Admite dos referencias. La **referencia de paridad** (α = β = 0, esto es, SOV = SOM) es el criterio con el que Binet y Field calcularon el exceso de voz (Danenberg et al., 2016, p. 140). La **referencia de Jones**, o la recta propia de la categoría, es la que Danenberg et al. (2016) consideran más prometedora como equilibrio, aunque en sus datos el respaldo empírico a esa ventaja sobre la paridad fue débil (pp. 140, 143).

El parámetro $k$ es la **velocidad de respuesta**: puntos de cuota ganados al año por cada punto de voz por encima del mantenimiento. Con la referencia de paridad, la cifra de Field se traduce de forma directa, 0,5 / 10, en **k ≈ 0,05**, valor que el propio documento equipara a una elasticidad publicitaria de 0,05 (Danenberg et al., 2016, p. 140).

Una magnitud auxiliar facilita la intuición: la **semivida** de la brecha, $\ln 2 / [k(1+\beta)]$, es el tiempo que la marca tarda en recorrer la mitad del camino hacia la cuota que su voz puede sostener. Con k = 0,05 y paridad, la semivida se acerca a catorce años; en una marca establecida, la cuota se desplaza con lentitud.

### 13.3 La fórmula de los dos años

Si la marca sostiene una SOV constante $v$ durante $T$ años, la ecuación tiene solución cerrada y puede despejarse la voz que conduce de la cuota actual $s_0$ a la cuota objetivo $s^\ast$ de forma explícita:

$$v \;=\; \underbrace{v^{\ast}(s^{\ast})}_{\text{mantenimiento en el objetivo}} \;+\; \underbrace{(1+\beta)\,(w-1)\,(s^{\ast}-s_0)}_{\text{prima de crecimiento}}, \qquad w \;=\; \frac{1}{1-e^{-k(1+\beta)T}} .$$

La SOV del plan se descompone, por tanto, en dos sumandos con significado propio: la voz que hará falta para conservar la cuota objetivo una vez alcanzada y una **prima de crecimiento** proporcional a los puntos por ganar. El **multiplicador** $w$ resume en un solo número la velocidad de la categoría y la paciencia del plan: cuanto más lenta la respuesta o más corto el horizonte, mayor es $w$ y más cara cada décima de cuota.

**La regla del 1,5 como caso particular.** Con la referencia de paridad, una marca que parte de cero ($s_0 = 0$) y un horizonte de dos años, la fórmula se reduce a $v = w\,s^\ast$. La regla del 1,5 equivale a $w = 1{,}5$, es decir, a $e^{-2k} = 1/3$ y $k = \ln 3 / 2 \approx 0{,}55$ al año, con una semivida de 1,3 años: esa es la velocidad de respuesta que la regla presupone. Con esa misma velocidad, la regla ampliada para cualquier punto de partida resulta

$$v \;=\; 1{,}5\,s^\ast \;-\; 0{,}5\,s_0 ,$$

que admite una lectura inmediata: **la cuota objetivo más medio punto de voz por cada punto de cuota que se quiere ganar**. Para $s_0 = 0$ reproduce exactamente la regla original.

La velocidad implícita en la regla del 1,5 es unas diez veces la de Field. Ambas cifras describen regímenes distintos: la primera, lanzamientos; la segunda, marcas maduras de gran consumo. La diferencia es coherente con la regularidad de que las elasticidades publicitarias son menores en marcas grandes y consolidadas que en marcas pequeñas o nuevas (Danenberg et al., 2016, pp. 140, 144).

**Multiplicador w para un horizonte de dos años con referencia de paridad**

| <sub>k (puntos de SOM al año por punto de exceso)</sub> | <sub>Semivida</sub> | <sub>w</sub> | <sub>Lectura</sub> |
| ---: | ---: | ---: | :--- |
| <sub>0,05</sub> | <sub>13,9 años</sub> | <sub>10,5</sub> | <sub>Marca madura de gran consumo (orden de magnitud de Field)</sub> |
| <sub>0,10</sub> | <sub>6,9 años</sub> | <sub>5,5</sub> | <sub>Valor ilustrativo</sub> |
| <sub>0,25</sub> | <sub>2,8 años</sub> | <sub>2,5</sub> | <sub>Valor ilustrativo</sub> |
| <sub>0,55</sub> | <sub>1,3 años</sub> | <sub>1,5</sub> | <sub>Velocidad implícita en la regla del 1,5</sub> |

### 13.4 Calibrar k, el parámetro decisivo

Toda la fórmula depende de $k$, y conviene estimarlo antes que suponerlo. Si se dispone de un **panel** de la categoría (varios años de SOV y SOM por marca), `sov_efecto_esov()` estima η en $d\ln\mathrm{SOM} = \eta\,\ln(\mathrm{SOV}/\mathrm{SOM})$ (apartado 10.5). Cuando SOV y SOM son próximas, $\ln(v/s) \approx (v-s)/s$ y, por tanto, $ds/dt \approx \eta\,(v-s)$: **el η estimado puede emplearse como k con la referencia de paridad**, expresado en la periodicidad del panel; la aproximación es tanto más fiel cuanto menor sea la distancia entre voz y cuota.

Sin panel, lo prudente es **acotar** el presupuesto con los dos anclajes de la tabla anterior, 0,05 y 0,55, y tratar el intervalo resultante como el rango de decisiones defendibles. Dos cautelas completan el cuadro. La primera: un $k$ estimado frente a la paridad no es trasladable sin más a la referencia de Jones,, porque mide la respuesta a otro exceso; con la referencia de Jones, $k$ debe estimarse frente a esa recta. La segunda: la respuesta a la publicidad es heterogénea y no siempre detectable; en el metaanálisis de Sethuraman et al. (2011), poco más de la mitad de las 437 elasticidades con error típico calculable resultaron significativamente mayores que cero al 95 % (citado en Danenberg et al., 2016, p. 145).

### 13.5 Ejemplo resuelto: Marca E, del 8 % al 10 % en dos años

Marca E es la marca ficticia de `sov_plantilla()`: SOM del 8 % y SOV del 9 %, con un ESOV de +1 punto. El objetivo es una cuota del 10 % al cierre del segundo año. Para la recta de la categoría se toma la referencia de Jones que usa el paquete, α = 6,4 y β = −0,38; el intercepto es el que Danenberg et al. (2016, p. 142) atribuyen a Jones.

*Paso a paso con la referencia de paridad y k = 0,55.* El multiplicador vale w = 1,5; la SOV de mantenimiento en el objetivo es v\*(10) = 10; la prima es 1 × 0,5 × 2 = 1. La SOV del plan es **11,0 %** en cada uno de los dos años.

*Paso a paso con la referencia de Jones y k = 0,55.* Ahora 1 + β = 0,62 y w = 1 / (1 − e<sup>−0,55 × 0,62 × 2</sup>) = 2,02; el mantenimiento en el objetivo es 6,4 + 0,62 × 10 = 12,6; la prima es 0,62 × 1,02 × 2 = 1,27. La SOV del plan es **13,9 %**.

*De la cuota de voz al presupuesto.* Si la competencia invierte $X$ y la marca $A$, entonces $v = A/(A+X)$ y

$$A \;=\; X\,\frac{v}{100-v}.$$

La relación no es lineal: con $X$ constante, pasar del 9 % al 11 % de SOV exige un 25 % más de inversión, no un 22 %. La tabla compara los planes con un índice de presupuesto en el que la inversión actual vale 100; las cuotas de los años 1 y 2 se calculan con el modelo correspondiente a cada fila.

| <sub>Plan</sub> | <sub>SOV, años 1 y 2</sub> | <sub>Presupuesto (hoy = 100)</sub> | <sub>SOM al cierre del año 1</sub> | <sub>SOM al cierre del año 2</sub> |
| :--- | ---: | ---: | ---: | ---: |
| <sub>Regla del 1,5 (1,5 × 10), paridad, k = 0,55</sub> | <sub>15,0 %</sub> | <sub>178</sub> | <sub>11,0 %</sub> | <sub>12,7 %</sub> |
| <sub>Ampliado, paridad, k = 0,55</sub> | <sub>11,0 %</sub> | <sub>125</sub> | <sub>9,3 %</sub> | <sub>10,0 %</sub> |
| <sub>Ampliado, Jones, k = 0,55</sub> | <sub>13,9 %</sub> | <sub>163</sub> | <sub>9,2 %</sub> | <sub>10,0 %</sub> |
| <sub>Ampliado, paridad, k = 0,05</sub> | <sub>29,0 %</sub> | <sub>413</sub> | <sub>9,0 %</sub> | <sub>10,0 %</sub> |

La tabla admite tres lecturas. **Ignorar el punto de partida encarece el plan y lo desborda**: la regla original, aplicada a una marca que no nace de cero, cuesta 53 puntos de índice más que la versión ampliada y lleva la cuota al 12,7 %, por encima del objetivo. **La corrección de Jones eleva la factura**: con un 8 % de cuota, la recta de Jones fija el mantenimiento en una SOV del 11,4 %, de modo que la Marca E, con su 9 % actual, ya invierte por debajo de lo que su tamaño exige y parte de un déficit. **Con la velocidad de una marca madura, el objetivo deja de ser creíble**: cuadruplicar el presupuesto es una señal para revisar la meta o el horizonte, no para aprobar el gasto; con k = 0,05, la SOV del 15 % que prescribe la regla del 1,5 solo llevaría la cuota al 8,7 %.

### 13.6 Consecuencias en los mapas: salto, deslizamiento y aterrizaje

Un plan de este tipo dibuja en ambos mapas la misma secuencia de tres movimientos. Las figuras muestran la Marca E con las dos referencias y k = 0,55; el punto negro es la situación actual, los círculos marcan el inicio y el cierre de cada año, y el cuadrado, la SOV de mantenimiento a partir del tercer año.

<img src="man/figures/README-peckham-esov-1.png" width="90%" />

**En el mapa ESOV–SOM.** El **salto** es vertical: el primer día la cuota no cambia y el ESOV aumenta en tantos puntos como SOV se añaden (+2 con paridad, +4,9 con Jones). El **deslizamiento** sigue una recta de pendiente −1, porque con la voz constante cada punto de cuota ganado resta un punto de ESOV; además, el avance se frena a medida que la marca se aproxima a su referencia (con paridad, 1,27 puntos de cuota el primer año y 0,73 el segundo). El **aterrizaje** es de nuevo vertical: al rebajar la voz al mantenimiento, el punto cae sobre la línea ESOV = 0 con paridad, o sobre la recta de Jones, a +2,6 puntos, con esa referencia.

<img src="man/figures/README-peckham-mapa-1.png" width="90%" />

**En el mapa SOV–SOM.** Los mismos movimientos giran noventa grados. El salto es horizontal y adentra a la marca en la zona de inversión; el deslizamiento es vertical, porque la voz no cambia mientras la cuota sube; el aterrizaje la devuelve hacia la izquierda, hasta la diagonal o hasta la recta de Jones. La distancia horizontal entre el tramo vertical y el cuadrado es, en cada año, la prima de crecimiento que se está pagando.

De esta geometría se desprenden dos consecuencias prácticas. La primera: **que el ESOV disminuya durante el plan no indica que el plan esté fallando**; es la consecuencia mecánica de crecer con la voz constante. La segunda: **el aterrizaje es parte del plan**. Si la marca no rebaja su voz al cierre del segundo año, sigue creciendo hacia la cuota en la que esa voz sería de mantenimiento, el 11,0 % con paridad o el 12,0 % con Jones, y paga por un crecimiento que no estaba en el objetivo.

### 13.7 Lo que el método no resuelve

El modelo supone que la respuesta es lineal en el exceso de voz. Danenberg et al. (2016) conjeturan que el efecto de un aumento de voz depende más de su distancia al equilibrio que del cambio proporcional, y piden comprobar si crece de forma monótona con esa distancia (p. 145); el método adopta esa hipótesis como supuesto de trabajo. La recta de mantenimiento varía con la categoría y con el año, y los autores desaconsejan sustituir la recta propia por la media de Jones cuando aquella puede estimarse (p. 144); con pocas marcas, el intervalo de β que ofrece `sov_analiza()` debe trasladarse a la SOV del plan. La cuota responde también a factores ajenos al peso publicitario, como la innovación o la entrada de competidores, que pesaron con claridad en los mercados de proveedores de internet estudiados (pp. 142–143). Las cuotas suman 100: si la competencia reacciona, el mismo presupuesto compra menos voz, y $A$ debe recalcularse con la previsión de $X$. Por último, la fórmula no maximiza beneficios: Danenberg et al. (2016) recomiendan no fijar el presupuesto con un único criterio y combinarlo con un cálculo de optimización del beneficio basado en elasticidades y con el método de objetivo y tarea (p. 145).

### 13.8 Referencias de este apartado

Danenberg, N., Kennedy, R., Beal, V., & Sharp, B. (2016). Advertising budgeting: A reinvestigation of the evidence on brand size and spend. *Journal of Advertising, 45*(1), 139–146. https://doi.org/10.1080/00913367.2015.1090938

Jones, J. P. (1990). Ad spending: Maintaining market share. *Harvard Business Review, 68*(1), 38–43.

Peckham, J. O. (1972). *The wheel of marketing*. A. C. Nielsen.

## 14. Referencia de funciones

| <sub>Función</sub> | <sub>Para qué sirve</sub> |
| :--- | :--- |
| <sub>`sov_demo()`</sub> | <sub>Recorrido guiado de todo el flujo</sub> |
| <sub>`sov_asistente()`</sub> | <sub>Aplicación Shiny sin código</sub> |
| <sub>`sov_plantilla()`</sub> | <sub>Crea un CSV de muestra compatible con Excel</sub> |
| <sub>`sov_ejemplo()`</sub> | <sub>Ruta del CSV de ejemplo (Ad Age, 2019)</sub> |
| <sub>`adage2019`</sub> | <sub>Datos reales de ejemplo</sub> |
| <sub>`sov_lee()`</sub> | <sub>Lee un CSV (separador, decimal y codificación automáticos)</sub> |
| <sub>`sov_prepara()`</sub> | <sub>Estandariza y valida los datos</sub> |
| <sub>`sov_analiza()`</sub> | <sub>Análisis completo por categoría</sub> |
| <sub>`sov_interpreta()`</sub> | <sub>Lectura en lenguaje llano</sub> |
| <sub>`sov_tabla()`</sub> | <sub>Tablas de resultados (data.frame o HTML)</sub> |
| <sub>`sov_grafico()`, `sov_grafico_bosque()`, `sov_mapa()`, `plot()`</sub> | <sub>Gráficos (ESOV por SOM, bosque de pendientes, mapa SOV–SOM)</sub> |
| <sub>`sov_informe()`</sub> | <sub>Informe HTML autocontenido (incluye las dos guías)</sub> |
| <sub>`sov_guia()`</sub> | <sub>Guía paso a paso: de las cuotas a la brecha de una marca (`"marca"`) o de los puntos a la recta (`"sector"`)</sub> |
| <sub>`sov_ajusta()`, `sov_theil_sen()`, `sov_influencia()`, `sov_bootstrap()`, `sov_formas()`, `sov_elasticidad()`, `sov_heterogeneidad()`</sub> | <sub>Componentes del análisis con vectores</sub> |
| <sub>`sov_postulados()`</sub> | <sub>Catálogo de postulados de simulación</sub> |
| <sub>`sov_parametros()`</sub> | <sub>Parámetros y procedencia</sub> |
| <sub>`sov_calibra()`</sub> | <sub>Calibración con datos reales</sub> |
| <sub>`sov_simula()`, `sov_simula_dinamica()`</sub> | <sub>Generación de datos sintéticos</sub> |
| <sub>`sov_efecto_esov()`</sub> | <sub>Efecto del ESOV sobre la variación de cuota (panel)</sub> |
| <sub>`sov_valida_simulacion()`</sub> | <sub>Estudio de recuperación (sesgo, RMSE, cobertura)</sub> |
| <sub>`sov_referencias()`</sub> | <sub>Bibliografía del paquete</sub> |
| <sub>`sov_glosario()`</sub> | <sub>Definición de términos</sub> |

La ayuda de cada función está disponible con `?sov_analiza`,
`help(package = "mediaSOV")` y `vignette("primeros-pasos", "mediaSOV")`
(si instaló las viñetas).

### Referencias bibliográficas

``` r
sov_referencias()
```

- Jones, J. P. (1990). Ad spending: Maintaining market share. Harvard Business Review, 68(1), 38-42.
- Hansen, F., & Christensen, L. B. (2005). Share of voice/share of market and long-term advertising effects. International Journal of Advertising, 24(3), 297-320.
- Danenberg, N., Kennedy, R., Beal, V., & Sharp, B. (2016). Advertising budgeting: A reinvestigation of the evidence on brand size and spend. Journal of Advertising, 45(1), 139-146.
- Sethuraman, R., Tellis, G. J., & Briesch, R. A. (2011). How well does advertising work? Generalizations from meta-analysis of brand advertising elasticities. Journal of Marketing Research, 48(3), 457-471.
- Graham, C. (2009). What's the point of marketing anyway? The prevalence, temporal extent and implications of long-term market share equilibrium. Journal of Marketing Management.
- Bae, Y. H., et al. (2024). Category-level drivers of the market share-rank power law relationship. European Journal of Marketing.
- Morais, J., Thomas-Agnan, C., & Simioni, M. (2017). Using compositional and Dirichlet models for market share regression. Journal of Applied Statistics.
- Binet, L., & Field, P. (2007). Marketing in the Era of Accountability. WARC.
- Binet, L., & Field, P. (2013). The Long and the Short of It. IPA.
- Theil, H. (1950). A rank-invariant method of linear and polynomial regression analysis. Nederlandse Akademie van Wetenschappen, Proceedings, 53, 386-392, 521-525, 1397-1412.
- Sen, P. K. (1968). Estimates of the regression coefficient based on Kendall's tau. Journal of the American Statistical Association, 63(324), 1379-1389.
- Cook, R. D. (1977). Detection of influential observation in linear regression. Technometrics, 19(1), 15-18.
- Belsley, D. A., Kuh, E., & Welsch, R. E. (1980). Regression Diagnostics. Wiley.
- Hurvich, C. M., & Tsai, C.-L. (1989). Regression and time series model selection in small samples. Biometrika, 76(2), 297-307.
- Efron, B. (1979). Bootstrap methods: Another look at the jackknife. The Annals of Statistics, 7(1), 1-26.

## 15. Solución de problemas

| <sub>Síntoma</sub> | <sub>Causa probable</sub> | <sub>Solución</sub> |
| :--- | :--- | :--- |
| <sub>`no se puede abrir el URL` / error en `install_github`</sub> | <sub>Sin conexión o proxy</sub> | <sub>Descargue el ZIP (apartado 2.3)</sub> |
| <sub>Error por Pandoc en `sov_informe()`</sub> | <sub>Pandoc no instalado</sub> | <sub>Use RStudio o instale Pandoc (<https://pandoc.org/installing.html>)</sub> |
| <sub>`Falta el paquete 'shiny'`</sub> | <sub>Paquete opcional ausente</sub> | <sub>`install.packages("shiny")`</sub> |
| <sub>«columna» no encontrada al leer</sub> | <sub>Nombres de columna no reconocidos</sub> | <sub>Renómbrelos (apartado 4.1) o use `sov_plantilla()`</sub> |
| <sub>Cifras 100 veces menores o mayores</sub> | <sub>Cuotas en proporción (0–1)</sub> | <sub>Multiplique por 100</sub> |
| <sub>«menos de 4 marcas»</sub> | <sub>Categoría con pocas marcas</sub> | <sub>Se omite; añada marcas o agrupe categorías</sub> |
| <sub>Acentos mal en consola de Windows</sub> | <sub>Codificación de la consola</sub> | <sub>El archivo se lee bien; use RStudio o `Sys.setlocale("LC_ALL", "es_ES.UTF-8")`</sub> |
| <sub>Excel muestra todo en una columna</sub> | <sub>Separador distinto del configurado</sub> | <sub>Use la plantilla del paquete o *Datos → Texto en columnas*</sub> |

Si el problema persiste, abra una *issue* en
<https://github.com/majesus/mediaSOV/issues> indicando la salida de
`sessionInfo()` y un ejemplo mínimo reproducible.

## 16. Limitaciones y procedencia de los datos

- Las cuotas de una categoría suman 100 %, por lo que SOV y SOM no son
  independientes y la relación puede contener efectos de cierre.
- Con 6–10 marcas por categoría, la potencia estadística es baja y el
  intervalo clásico tiende a ser demasiado estrecho; use también HC3,
  Theil-Sen y bootstrap.
- Los **datos reales de ejemplo** (Ad Age, 2019) se transcribieron a partir de material docente.
- Los coeficientes de la curva de referencia de Jones (α = 6,4; β = −0,38) proceden de un ajuste lineal a la tabla de Jones (1990); el intercepto coincide con el que Danenberg et al. (2016, p. 142) atribuyen a Jones.
- La SOV del plan del método Peckham 1,5 ampliado (apartado 13) depende de la velocidad de respuesta k, que debe calibrarse con datos de la categoría; los dos anclajes que se ofrecen son órdenes de magnitud.
- La elasticidad η = 0,24 de la simulación dinámica es un **supuesto
  operativo**.
- Los datos sintéticos no son evidencia empírica.

## 17. Cita, licencia y contribuciones

``` r
citation("mediaSOV")
```

Licencia **MIT** (véase `LICENSE`). Sugerencias y errores:
<https://github.com/majesus/mediaSOV/issues>.

Autor y mantenedor: Manuel Jesús Sánchez-Franco, Universidad de Sevilla.
