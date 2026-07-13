# Librerías.
# -------------------------------------------------------------------------------------

library(shiny)
library(shinyWidgets)
library(dplyr)
library(plotly)
library(leaflet)
library(lubridate)
library(stringr)
library(styler)
library(bslib)


# Seteos.
# -------------------------------------------------------------------------------------

     # Carpeta de trabajo.
     setwd("C:/Users/luis/OneDrive - Ingenieros Consultores Asociados/FCEA/2026 - Ciencia de Datos en R/Proyecto")
     
     # Constantes.
     cTodos <- "TODOS"

# Importo otros archivos R (funciones).
# -------------------------------------------------------------------------------------

source("./R_SIPC/cargarDatos.r")
source("./R_SIPC/server.r")
source("./R_SIPC/ui.r")

# El DF principal y el DF de barrios.
# -------------------------------------------------------------------------------------

vLista_Resultado <- fCargarDFs("./Datos/SIPC")

# Los dos dataframes.
vDF_Barrios <- vLista_Resultado$DF_Barrios
vDF_Main <- vLista_Resultado$DF_Main

# Estos pasos se justifican en el "análisis exploratorio".
vDF_Main <- vDF_Main |>
            group_by(producto) |>
            mutate(p99_producto = quantile(precio,
                                           0.99,
                                           na.rm = TRUE),
                   es_outlier = precio > p99_producto) |>
            filter(!es_outlier) |>
            ungroup()     

# Ajusto el nombre del vDF_Barrios.
vDF_Barrios <- vDF_Barrios |>
               rename(barrio = BARRIO)

# Limpio.
rm(vLista_Resultado)

# Vectores con las categorías para: es_oferta; barrio; producto.
# -------------------------------------------------------------------------------------

vec_EsOferta <- vDF_Main |>
                distinct(es_oferta) |>
                pull(es_oferta)

vec_Barrio <- vDF_Main |>
     select(barrio) |>
     distinct() |> 
     arrange(barrio) |>
     pull(barrio)

vec_Producto <- vDF_Main |>
     select(producto) |>
     distinct() |> 
     arrange(producto) |>
     pull(producto)


# Ejecutar la app
shinyApp(ui,
         server)