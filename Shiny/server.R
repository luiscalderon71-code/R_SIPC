# 15 de Julio.

server <- function(input, output, session) {

     # Inicializo el selector de productos de la segunda pestaña.
     observe({
          updatePickerInput(
               session = session,
               inputId = "tab2_producto_cbx",
               choices = vec_Producto
          )
     })

     # -------------------------------------------------------------------------
     # TAB 1: LÓGICA DE FILTROS
     # -------------------------------------------------------------------------

     # Filtra la lista de productos según el texto ingresado por el usuario.
     observeEvent(input$tab1_filtroProducto_txt, {

          vec_Producto_Filtrado <- if (
               input$tab1_filtroProducto_txt != ""
          ) {
               str_subset(
                    vec_Producto,
                    regex(
                         input$tab1_filtroProducto_txt,
                         ignore_case = TRUE
                    )
               )
          } else {
               vec_Producto
          }

          updatePickerInput(
               session = session,
               inputId = "tab1_producto_cbx",
               choices = vec_Producto_Filtrado
          )
     })

     # Actualiza los barrios disponibles según los productos seleccionados
     # y la decisión de incluir o excluir registros en oferta.
     observeEvent(
          list(
               input$tab1_producto_cbx,
               input$tab1_incluirofertas_chk
          ),
          {
               vDF_Filtrado <- vDF_Main

               if (length(input$tab1_producto_cbx)) {
                    vDF_Filtrado <- vDF_Filtrado |>
                         filter(
                              producto %in% input$tab1_producto_cbx
                         )
               }

               # Checkbox marcado: se incluyen ofertas y precios regulares.
               # Checkbox desmarcado: se excluyen únicamente las ofertas.
               if (!input$tab1_incluirofertas_chk) {
                    vDF_Filtrado <- vDF_Filtrado |>
                         filter(es_oferta == 0)
               }

               vec_Barrios <- vDF_Filtrado |>
                    select(barrio) |>
                    distinct() |>
                    arrange(barrio) |>
                    pull(barrio)

               updatePickerInput(
                    session = session,
                    inputId = "tab1_barrios_cbx",
                    choices = vec_Barrios
               )
          }
     )

     # -------------------------------------------------------------------------
     # TAB 1: DATOS PROCESADOS
     # -------------------------------------------------------------------------

     # Calcula el crecimiento porcentual semanal respecto del primer precio
     # promedio disponible para cada producto.
     react_DatosProcesados_tab1 <- reactive({

          req(input$tab1_producto_cbx)

          vDF_Filtrado <- vDF_Main |>
               filter(
                    producto %in% input$tab1_producto_cbx
               )

          if (length(input$tab1_barrios_cbx)) {
               vDF_Filtrado <- vDF_Filtrado |>
                    filter(
                         barrio %in% input$tab1_barrios_cbx
                    )
          }

          # Checkbox marcado: se incluyen ofertas y precios regulares.
          # Checkbox desmarcado: se excluyen únicamente las ofertas.
          if (!input$tab1_incluirofertas_chk) {
               vDF_Filtrado <- vDF_Filtrado |>
                    filter(es_oferta == 0)
          }

          vDF_Filtrado |>
               group_by(producto, semana) |>
               summarise(
                    precio_prom = mean(
                         precio,
                         na.rm = TRUE
                    ),
                    .groups = "drop"
               ) |>
               group_by(producto) |>
               arrange(
                    semana,
                    .by_group = TRUE
               ) |>
               mutate(
                    precio_base = first(precio_prom),
                    crecimiento_pct = (
                         (precio_prom - precio_base) /
                              precio_base
                    ) * 100
               ) |>
               ungroup()
     })

     # -------------------------------------------------------------------------
     # TAB 2: DATOS PROCESADOS
     # -------------------------------------------------------------------------

     # Calcula la variación absoluta de precio y la vincula con la geometría
     # de los barrios.
     react_DatosProcesados_tab2 <- reactive({

          req(
               input$tab2_producto_cbx,
               input$tab2_rango_fechas
          )

          vDF <- vDF_Main |>
               filter(
                    producto == input$tab2_producto_cbx,
                    fecha >= input$tab2_rango_fechas[1],
                    fecha <= input$tab2_rango_fechas[2]
               )

          # Si el checkbox está desmarcado, se excluyen las ofertas.
          if (!input$tab2_incluirofertas_chk) {
               vDF <- vDF |>
                    filter(es_oferta == 0)
          }

          # Calcula la diferencia entre el primer y el último precio
          # disponible dentro del período analizado.
          vDF_Var <- vDF |>
               group_by(barrio) |>
               summarise(
                    p_inicial = first(precio[order(fecha)]),
                    p_final = last(precio[order(fecha)]),
                    incremento_pesos = p_final - p_inicial,
                    .groups = "drop"
               ) |>
               mutate(
                    incremento_pesos = ifelse(
                         is.finite(incremento_pesos),
                         incremento_pesos,
                         0
                    )
               )

          # Une los resultados estadísticos con los polígonos de barrios.
          vDF_Barrios |>
               mutate(
                    barrio_join = toupper(barrio)
               ) |>
               left_join(
                    vDF_Var |>
                         mutate(
                              barrio_join = toupper(barrio)
                         ),
                    by = "barrio_join"
               ) |>
               mutate(
                    barrio_final = coalesce(
                         barrio.x,
                         barrio_join
                    )
               )
     })

     # -------------------------------------------------------------------------
     # SALIDAS
     # -------------------------------------------------------------------------

     # Gráfico interactivo de la primera pestaña.
     output$tab1_grafico_crecimiento <- renderPlotly({

          datos <- react_DatosProcesados_tab1()
          req(nrow(datos) > 0)

          p <- ggplot(
               datos,
               aes(
                    x = semana,
                    y = crecimiento_pct,
                    color = producto,
                    group = producto
               )
          ) +
               geom_line(linewidth = 1.2) +
               geom_point(
                    aes(
                         text = paste(
                              "Producto:", producto,
                              "<br>Semana:", semana,
                              "<br>Crecimiento:",
                              round(crecimiento_pct, 2),
                              "%"
                         )
                    ),
                    size = 2
               ) +
               theme_light() +
               theme(
                    panel.grid.minor = element_blank(),
                    legend.position = "bottom",
                    text = element_text(family = "sans")
               )

          ggplotly(
               p,
               tooltip = "text"
          ) |>
               layout(
                    hoverlabel = list(
                         bgcolor = "white"
                    )
               )
     })

     # Mapa interactivo de la segunda pestaña.
     output$tab2_mapa_resultados <- renderLeaflet({

          data_map <- react_DatosProcesados_tab2()
          req(data_map)

          pal <- colorNumeric(
               palette = "RdYlGn",
               domain = data_map$incremento_pesos,
               reverse = TRUE,
               na.color = "transparent"
          )

          leaflet(data_map) |>
               addPolygons(
                    fillColor = ~pal(incremento_pesos),
                    weight = 1,
                    opacity = 1,
                    color = "white",
                    fillOpacity = 0.5,
                    highlightOptions = highlightOptions(
                         weight = 3,
                         color = "black"
                    ),
                    label = ~paste0(
                         barrio_final,
                         ": $",
                         round(incremento_pesos, 0)
                    )
               ) |>
               addLegend(
                    pal = pal,
                    values = ~incremento_pesos,
                    title = "Incremento ($)",
                    position = "bottomright"
               )
     })

     # Lista de barrios sin información para el producto y período elegidos.
     output$tab2_lista_barrios_vacias <- renderUI({

          data_map <- react_DatosProcesados_tab2()
          req(data_map)

          barrios_vacias <- data_map |>
               filter(is.na(incremento_pesos)) |>
               pull(barrio_final)

          if (length(barrios_vacias) == 0) {
               tags$p(
                    "Todos los barrios tienen datos registrados."
               )
          } else {
               tags$ul(
                    lapply(
                         sort(unique(barrios_vacias)),
                         function(x) tags$li(x)
                    )
               )
          }
     })
}
