server <- function(input, output, session) {
     
     
     observeEvent(input$filtroProducto_txt, {
          
          #print(input$filtroProducto_txt)
          
          # Filtro el vector.
          if (input$filtroProducto_txt != '') {
               vec_Producto_Filtrado <- str_subset(vec_Producto,
                                                   regex(input$filtroProducto_txt,
                                                         ignore_case = TRUE))
          } else {
               vec_Producto_Filtrado <- vec_Producto
          }

          # Le mando los nuevos valores a "producto_cbx".
          updatePickerInput(session = session,
                            inputId = "producto_cbx",
                            choices = vec_Producto_Filtrado)
          
     })
     
     
     observeEvent(list(input$producto_cbx, input$incluirofertas_chk), {
     
          # Muestro los barrios.
          vDF_Filtrado <- vDF_Main
          
          print(input$filtroProducto_txt)
          print(input$incluir_ofertas)
          
          if (length(input$producto_cbx)) {
               vDF_Filtrado <- vDF_Filtrado |>
                               filter(producto %in% input$producto_cbx)
          }
          
          if (input$incluirofertas_chk == 1) {
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
                            inputId = "barrios_cbx",
                            choices = vec_Barrios)        
     })
     
     
     # =======================================================
     # 2. PROCESAMIENTO DE DATOS REACTIVO
     # =======================================================
     
     react_DatosProcesados <- reactive({
          
          # Valido que al menos haya algún producto seleccionado para no calcular sobre el vacío
          req(input$producto_cbx)
          
          vDF_Filtrado <- vDF_Main |> 
               filter(producto %in% input$producto_cbx)
          
          # Aplico filtro de barrios (si el usuario seleccionó alguno).
          if (length(input$barrios_cbx)) {
               vDF_Filtrado <- vDF_Filtrado |> 
                    filter(barrio %in% input$barrios_cbx)
          }
          
          # Aplico filtro de ofertas
          if (!input$incluirofertas_chk) {
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
     # =======================================================
     # 3. RENDERIZADO DEL GRÁFICO (PLOTLY)
     # =======================================================
     
     output$grafico_crecimiento <- renderPlotly({
          
          # Obtenemos los datos filtrados y calculados
          datos <- react_DatosProcesados()
          
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
     
}


