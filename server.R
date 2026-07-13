server <- function(input, output, session) {
     
     # Inicializo el selector de productos al cargar la app para evitar que quede vacío
     observe({
          updatePickerInput(
               session = session,
               inputId = "tab2_producto_cbx",
               choices = vec_Producto
          )
     })     
     
     # --- Lógica de filtros (Tab 1) ---
     # Filtro la lista de productos en tiempo real según lo que escribo en el campo de texto
     observeEvent(input$tab1_filtroProducto_txt, {
          vec_Producto_Filtrado <- if (input$tab1_filtroProducto_txt != '') {
               str_subset(vec_Producto, regex(input$tab1_filtroProducto_txt, ignore_case = TRUE))
          } else { vec_Producto }
          updatePickerInput(session = session, inputId = "tab1_producto_cbx", choices = vec_Producto_Filtrado)
     })
     
     # --- Lógica de barrios (Tab 1) ---
     # Refresco los barrios disponibles basándome en los productos y ofertas seleccionadas
     observeEvent(list(input$tab1_producto_cbx, input$tab1_incluirofertas_chk), {
          vDF_Filtrado <- vDF_Main
          if (length(input$tab1_producto_cbx)) vDF_Filtrado <- vDF_Filtrado |> filter(producto %in% input$tab1_producto_cbx)
          if (input$tab1_incluirofertas_chk == 1) vDF_Filtrado <- vDF_Filtrado |> filter(es_oferta == 1)
          vec_Barrios <- vDF_Filtrado |> select(barrio) |> distinct() |> arrange(barrio) |> pull(barrio)
          updatePickerInput(session = session, inputId = "tab1_barrios_cbx", choices = vec_Barrios)        
     })
     
     # --- Reactive Tab 1 ---
     # Proceso los datos para el gráfico de líneas calculando el crecimiento porcentual acumulado
     react_DatosProcesados_tab1 <- reactive({
          req(input$tab1_producto_cbx)
          vDF_Filtrado <- vDF_Main |> filter(producto %in% input$tab1_producto_cbx)
          if (length(input$tab1_barrios_cbx)) vDF_Filtrado <- vDF_Filtrado |> filter(barrio %in% input$tab1_barrios_cbx)
          if (input$tab1_incluirofertas_chk == 0) vDF_Filtrado <- vDF_Filtrado |> filter(es_oferta == 1) else vDF_Filtrado <- vDF_Filtrado |> filter(es_oferta == 0)
          
          vDF_Filtrado |>
               group_by(producto, semana) |> summarise(precio_prom = mean(precio, na.rm = TRUE), .groups = "drop") |> 
               group_by(producto) |> arrange(semana, .by_group = TRUE) |> 
               mutate(precio_base = first(precio_prom), crecimiento_pct = ((precio_prom - precio_base) / precio_base) * 100) |> 
               ungroup()
     })     
     
     # --- Reactive Tab 2 ---
     # Calculo la variación absoluta en pesos y realizo el cruce con la geometría de los barrios
     react_DatosProcesados_tab2 <- reactive({
          req(input$tab2_producto_cbx, input$tab2_rango_fechas)
          
          # Primero filtro los datos según los inputs del usuario
          vDF <- vDF_Main |>
               filter(producto == input$tab2_producto_cbx,
                      fecha >= input$tab2_rango_fechas[1],
                      fecha <= input$tab2_rango_fechas[2])
          
          if (!input$tab2_incluirofertas_chk) vDF <- vDF |> filter(es_oferta == 0)
          
          # Calculo la diferencia de precio entre el primer y último registro encontrado
          vDF_Var <- vDF |>
               group_by(barrio) |>
               summarise(
                    p_inicial = first(precio[order(fecha)]),
                    p_final = last(precio[order(fecha)]),
                    incremento_pesos = (p_final - p_inicial)
               ) |>
               mutate(incremento_pesos = ifelse(is.finite(incremento_pesos), incremento_pesos, 0))
          
          # Hago el left_join para unir los datos con los polígonos del mapa
          vDF_Barrios |>
               mutate(barrio_join = toupper(barrio)) |>
               left_join(vDF_Var |> mutate(barrio_join = toupper(barrio)), by = "barrio_join") |>
               mutate(barrio_final = coalesce(barrio.x, barrio_join))
     }) 
     
     # --- Renders ---
     # Renderizo el gráfico interactivo del Tab 1
     output$tab1_grafico_crecimiento <- renderPlotly({
          datos <- react_DatosProcesados_tab1()
          req(nrow(datos) > 0)
          
          # Usamos el mapeo 'text' para el tooltip y 'group' para el zoom
          p <- ggplot(datos, aes(x = semana, y = crecimiento_pct, color = producto, group = producto)) +
               geom_line(linewidth = 1.2) +
               theme_light() + # Cambia theme_minimal por theme_light o theme_bw
               theme(panel.grid.minor = element_blank(), # Elimina rejillas innecesarias
                     legend.position = "bottom",
                     text = element_text(family = "sans")) # Fuente limpia
          
          # El argumento tooltip="text" es clave para el zoom y la información
          ggplotly(p, tooltip = "text")
     })    
     
     # Renderizo el mapa interactivo del Tab 2
     output$tab2_mapa_resultados <- renderLeaflet({
          data_map <- react_DatosProcesados_tab2()
          req(data_map)
          
          # Configuro la paleta de colores de verde a rojo para mostrar el incremento de precio
          pal <- colorNumeric(palette = "RdYlGn", 
                              domain = data_map$incremento_pesos, 
                              reverse = TRUE,
                              na.color = "transparent")
          
          leaflet(data_map) |>
               addTiles() |>
               addPolygons(
                    fillColor = ~pal(incremento_pesos),
                    weight = 1, opacity = 1, color = "white", fillOpacity = 0.5,
                    highlightOptions = highlightOptions(weight = 3, color = "black"),
                    label = ~paste0(barrio_final, ": $", round(incremento_pesos, 0))
               ) |>
               addLegend(pal = pal, 
                         values = ~incremento_pesos, 
                         title = "Incremento ($)", 
                         position = "bottomright")
     })    
     
     # Genero la lista dinámica de barrios sin información registrada
     output$tab2_lista_barrios_vacias <- renderUI({
          data_map <- react_DatosProcesados_tab2()
          req(data_map)
          
          barrios_vacias <- data_map |> 
               filter(is.na(incremento_pesos)) |> 
               pull(barrio_final)
          
          if (length(barrios_vacias) == 0) {
               tags$p("Todos los barrios tienen datos registrados.")
          } else {
               # Presento los barrios faltantes en una lista ordenada
               tags$ul(
                    lapply(sort(unique(barrios_vacias)),
                           function(x) tags$li(x))
               )
          }
     })     
     
}