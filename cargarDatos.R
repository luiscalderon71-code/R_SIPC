# Imports.
library(tidyverse)
library(readr)
library(sf)

# Cargar desde FGDB.
fCargarDFs <- function(pRuta) {

     # Cargar el SHP de barrios
     # ------------------------------------------------------------------------------------------------

     vArchivo <- file.path(pRuta, paste0("barriosINE", ".shp"))          

     cat("Cargando shapefile de barrios...", vArchivo, "\n")
     
     vDF_Barrios <- st_read(vArchivo)
     vDF_Barrios <- st_make_valid(vDF_Barrios)
     vDF_Barrios <- vDF_Barrios |>
                    select(BARRIO)
     

     # VERIFICAR SI EXISTE EL RDS??
     vArchivo <- file.path(pRuta, paste0("datosProc.rds"))      
     
     if (file.exists(vArchivo)) {
          
          # Existe el RDS anterior.
          
          cat("Cache encontrado! Cargando a alta velocidad desde:", vArchivo, "\n")
          vDF_Main <- readRDS(vArchivo)
          
          
     } else {
         
          # No existe el RDS anterior.
          
          cat("No se encontró cache ! Generando todo desde archivos CSV...\n")
                    
          # Establecimientos.
          # ------------------------------------------------------------------------------------------------

          cat("Cargando establecimientos...\n")
          
          vArchivo <- file.path(pRuta, paste0("establecimiento.csv"))    
               
          vDF_Establecimientos <- read.csv2(vArchivo)
          
          vDF_Establecimientos <- vDF_Establecimientos |>
               filter(depto == 'Montevideo') |>
               rename(id_establecimiento = id.establecimientos) |>
               mutate(id_establecimiento = as.integer(id_establecimiento),
                      ccz = as.integer(ccz),
                      long_ok = as.numeric(str_replace_all(lat, ",", ".")),
                      lat_ok = as.numeric(str_replace_all(long, ",", "."))) |>
               select(id_establecimiento,
                      depto,
                      ccz,
                      long_ok,
                      lat_ok) |>
               drop_na()
          
          vDF_Establecimientos_Geo <- st_as_sf(vDF_Establecimientos, 
                                               coords = c("long_ok", "lat_ok"), 
                                               crs = 4326)
          
          vDF_Establecimientos_Geo <- st_join(vDF_Establecimientos_Geo,
                                              vDF_Barrios,
                                              join = st_intersects) |>
               mutate(departamento = depto,
                      barrio = BARRIO) |>
               select(id_establecimiento,
                      barrio) 
          
          vDF_Establecimientos <- st_drop_geometry(vDF_Establecimientos_Geo)
          
          vDF_IdEstablecimientos <- vDF_Establecimientos |>
               select(id_establecimiento) |>
               distinct()
          
          # DF Productos: Todos los campos.
          # ------------------------------------------------------------------------------------------------
     
          cat("Cargando productos...\n")
          
          vArchivo <- file.path(pRuta, paste0("productos.csv"))       
          
          vDF_Productos <- read.csv2(vArchivo,
                                     fileEncoding = "latin1")
          
          vDF_Productos <- vDF_Productos |>
               rename(id_producto = id.producto) |>
               mutate(id_producto = as.integer(id_producto)) |>
               drop_na()
          
          # DF Precios.
          # ------------------------------------------------------------------------------------------------

          cat("Cargando precios...\n")
               
          vArchivo <- file.path(pRuta, paste0("precios.csv"))      
               
          vDF_Precios <- read.csv(vArchivo,
                                  fileEncoding = "latin1")
          
          vDF_Precios_MVD <- vDF_Precios |> 
               rename(id_establecimiento = Establecimiento,
                      id_producto = Presentacion_Producto ) |>
               mutate(id_establecimiento = as.integer(id_establecimiento),
                      id_producto = as.integer(id_producto)) |>
               filter(id_establecimiento %in% vDF_IdEstablecimientos$id_establecimiento)
          
          vDF_Precios_MVD <- vDF_Precios_MVD |> 
               rename(id_preciodiario = ID_PrecioDiario, 
                      fecha = Fecha,
                      es_oferta = Oferta,
                      precio = Precio) |>
               mutate(id_preciodiario = as.integer(id_preciodiario),
                      fecha = ymd(fecha), 
                      es_oferta = as.integer(es_oferta),
                      precio = as.integer(precio),
                      mes = month(fecha)) |>
               select(id_preciodiario,
                      id_establecimiento,
                      id_producto,
                      fecha,
                      es_oferta,
                      precio)
          
          # DF completo para Montevideo: Inner join de vDF_Precios_MVD, vDF_Productos y vDF_Establecimientos
          # ------------------------------------------------------------------------------------------------

          cat("Inner join entre precios, productos y establecimientos...\n")
          
          vDF_Main <- vDF_Precios_MVD |> 
               inner_join(vDF_Establecimientos,
                          by = "id_establecimiento",
                          suffix = c('_precio', '_establecimiento')) |>
               inner_join(vDF_Productos,
                          by = "id_producto",
                          suffix = c('', '_producto')) |>
               mutate(semana = as.integer(difftime(fecha, as.Date("2025-01-01"), units = "weeks") + 1),
                      mes = month(fecha))               
          

          vArchivo <- file.path(pRuta, paste0("datosProc.rds"))      

          cat("Guardando cache en:", vArchivo, "\n")          
                    
          vDF_Main |> saveRDS(vArchivo)
          
          # Borro todo.
          # ------------------------------------------------------------------------------------------------

          cat("Limpiando...\n")
          
          rm(vDF_Establecimientos)
          rm(vDF_Establecimientos_Geo)
          rm(vDF_IdEstablecimientos)
          rm(vDF_Precios)
          rm(vDF_Precios_MVD)
          rm(vDF_Productos)

     }     

     # Retorno.
     vSalida <- list(
          DF_Main = vDF_Main,
          DF_Barrios = vDF_Barrios
     )     
     
     return(vSalida)
     
}


