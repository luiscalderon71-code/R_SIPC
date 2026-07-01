server <- function(input, output, session) {
     
     
     observeEvent(input$tab1_filtroProducto_txt, {
          
          # Filtro el vector.
          if (input$tab1_filtroProducto_txt != '') {
               vec_Producto_Filtrado <- str_subset(vec_Producto,
                                                   regex(input$tab1_filtroProducto_txt,
                                                         ignore_case = TRUE))
          } else {
               vec_Producto_Filtrado <- vec_Producto
          }

          # Le mando los nuevos valores a "producto_cbx".
          updatePickerInput(session = session,
                            inputId = "tab1_producto_cbx",
                            choices = vec_Producto_Filtrado)
          
     })
     
     observeEvent(input$tab2_filtroProducto_txt, {
          
          # Filtro el vector.
          if (input$tab2_filtroProducto_txt != '') {
               vec_Producto_Filtrado <- str_subset(vec_Producto,
                                                   regex(input$tab2_filtroProducto_txt,
                                                         ignore_case = TRUE))
          } else {
               vec_Producto_Filtrado <- vec_Producto
          }
          
          # Le mando los nuevos valores a "producto_cbx".
          updatePickerInput(session = session,
                            inputId = "tab2_producto_cbx",
                            choices = vec_Producto_Filtrado)
          
     })
     
     
     observeEvent(list(input$tab1_producto_cbx, input$tab1_incluirofertas_chk), {
     
          # Muestro los barrios.
          vDF_Filtrado <- vDF_Main
          
          if (length(input$tab1_producto_cbx)) {
               vDF_Filtrado <- vDF_Filtrado |>
                               filter(producto %in% input$tab1_producto_cbx)
          }
          
          if (input$tab1_incluirofertas_chk == 1) {
               vDF_Filtrado <- vDF_Filtrado |>
                    filter(es_oferta == 1)
          }
          
          vec_Barrios <- vDF_Filtrado |>
                         select(barrio) |>
                         distinct() |> 
                         arrange(barrio) |>
                         pull(barrio)
          
          print(length(vec_Barrios))
          
          updatePickerInput(session = session,
                            inputId = "tab1_barrios_cbx",
                            choices = vec_Barrios)        
     })
     
     
     # Reactive para el Tab1
     react_DatosProcesados_tab1 <- reactive({
          
          # Valido que al menos haya algún producto seleccionado para no calcular sobre el vacío
          req(input$tab1_producto_cbx)
          
          vDF_Filtrado <- vDF_Main |> 
               filter(producto %in% input$tab1_producto_cbx)
          
          # Aplico filtro de barrios (si el usuario seleccionó alguno).
          if (length(input$tab1_barrios_cbx)) {
               vDF_Filtrado <- vDF_Filtrado |> 
                    filter(barrio %in% input$tab1_barrios_cbx)
          }
          
          # Aplico filtro de ofertas.
          if (input$tab1_incluirofertas_chk == 0) {
               vDF_Filtrado <- vDF_Filtrado |> 
                    filter(es_oferta == 1)
          } else {
               vDF_Filtrado <- vDF_Filtrado |> 
                    filter(es_oferta == 0)
          }  
          
          
          # --- CÁLCULO DEL CRECIMIENTO ACUMULADO: ESTILO IPC ---
          vDF_Crecimiento <- vDF_Filtrado |>
               # Agrupo por producto y por semana para promediar precios si hay varios comercios
               group_by(producto, semana) |> 
               summarise(precio_prom = mean(precio, na.rm = TRUE),
                         .groups = "drop") |> 
               # Vuelvo a agrupar solo por producto para ordenar cronológicamente
               group_by(producto) |> 
               arrange(semana, .by_group = TRUE) |> 
               # Calculo la variación acumulada respecto al precio de la PRIMERA semana
               mutate(
                    precio_base = first(precio_prom),
                    crecimiento_pct = ((precio_prom - precio_base) / precio_base) * 100
               ) |> 
               
               # Opcional: NO filtro la primera semana. 
               # Al ser la base, dará exactamente 0% (ideal para ver el punto de partida en el gráfico).
               ungroup()
          
          return(vDF_Crecimiento)
     })     

     # Reactive para el Tab1
     react_DatosProcesados_tab2 <- reactive({
          
          # Valido que al menos haya algún producto seleccionado para no calcular sobre el vacío
          req(input$tab1_producto_cbx)
          
          vDF_Filtrado <- vDF_Main |> 
               filter(producto %in% input$tab1_producto_cbx)
          
          # Aplico filtro de ofertas.
          if (input$tab1_incluirofertas_chk == 0) {
               vDF_Filtrado <- vDF_Filtrado |> 
                    filter(es_oferta == 1)
          } else {
               vDF_Filtrado <- vDF_Filtrado |> 
                    filter(es_oferta == 0)
          }  
          
          
          # --- CÁLCULO DEL CRECIMIENTO ACUMULADO: ESTILO IPC ---
          vDF_Crecimiento <- vDF_Filtrado |>
               # Agrupo por producto y por semana para promediar precios si hay varios comercios
               group_by(producto, barrio) |> 
               summarise(precio_prom = mean(precio,
                                            na.rm = TRUE),
                         .groups = "drop") |> 
               # Vuelvo a agrupar solo por producto-}.
               group_by(producto) |> 
               # Calculo la variación acumulada respecto al precio de la PRIMERA semana
               mutate(
                    precio_base = first(precio_prom),
                    crecimiento_pct = ((precio_prom - precio_base) / precio_base) * 100
               ) |> 
               
               # Opcional: NO filtro la primera semana. 
               # Al ser la base, dará exactamente 0% (ideal para ver el punto de partida en el gráfico).
               ungroup()
          
          return(vDF_Crecimiento)
     })     
     
     
     # RENDERIZADO DEL GRÁFICO (PLOTLY)
     output$tab1_grafico_crecimiento <- renderPlotly({
          
          # Obtenemos los datos filtrados y calculados
          datos <- react_DatosProcesados_tab1()
          
          # Si tras los filtros el dataframe queda vacío, evitamos el error
          req(nrow(datos) > 0)
          
          # Creamos el gráfico base con ggplot2
          p <- ggplot(datos, aes(x = semana, y = crecimiento_pct, color = producto, group = producto)) +
               geom_line(linewidth = 0.8) +
               geom_point(size = 1.5, aes(text = paste("Producto:", producto,
                                                       "<br>Semana:", semana,
                                                       "<br>Crecimiento:", round(crecimiento_pct, 2), "%"))) +
               labs(x = "Semanas", y = "Crecimiento Semanal (%)", color = "Producto") +
               theme_minimal() +
               theme(legend.position = "bottom")
          
          # Lo transformamos en interactivo con Plotly, mapeando nuestro 'text' personalizado para el tooltip
          ggplotly(p, tooltip = "text")
     })    
     
     output$tab2_mapa_resultados <- renderLeaflet({
          leaflet() |>
          addTiles() |>  # Mapa base
          addPolygons(data = vDF_Barrios,
                      color = "#2c3e50",       # Color de la línea de los bordes
                      weight = 1.5,             # Grosor de la línea
                      fillColor = "#3498db",    # Color de relleno de los polígonos
                      fillOpacity = 0.5,        # Transparencia del relleno
                      
                      # Esto hace que se resalte la zona cuando pasás el mouse (interactividad)
                      highlightOptions = highlightOptions(
                           weight = 3,
                           color = "#e74c3c",
                           bringToFront = TRUE
                      ))
     })
     
     
}


