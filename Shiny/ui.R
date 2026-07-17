# ==========================================
# INTERFAZ DE USUARIO (UI)
# ==========================================

ui <- fluidPage(

     # Tema visual de la aplicación.
     theme = bs_theme(
          version = 5,
          bootswatch = "minty"
     ),

     titlePanel(
          tags$div(
               tags$small(
                    "Análisis SIPC: Monitor de variación de precios en Montevideo"
               )
          )
     ),

     tabsetPanel(

          # --------------------------------------------------------------------
          # TAB 1: MODIFICACIÓN PORCENTUAL DE PRECIOS
          # --------------------------------------------------------------------
          tabPanel(
               "Modificación porcentual de precios",

               wellPanel(
                    fluidRow(

                         # Filtro 1: búsqueda de productos.
                         column(
                              width = 2,
                              textInput(
                                   inputId = "tab1_filtroProducto_txt",
                                   label = "Buscar producto:",
                                   value = ""
                              )
                         ),

                         # Filtro 2: selección múltiple de productos.
                         column(
                              width = 3,
                              pickerInput(
                                   inputId = "tab1_producto_cbx",
                                   label = "Seleccionar productos:",
                                   choices = c(),
                                   multiple = TRUE,
                                   options = list(
                                        `actions-box` = TRUE,
                                        `deselect-all-text` = "Ninguno",
                                        `select-all-text` = "Todos",
                                        `none-selected-text` = "Sin selección"
                                   )
                              )
                         ),

                         # Filtro 3: selección múltiple de barrios.
                         column(
                              width = 3,
                              pickerInput(
                                   inputId = "tab1_barrios_cbx",
                                   label = "Barrios:",
                                   choices = c(),
                                   multiple = TRUE,
                                   options = list(
                                        `actions-box` = TRUE,
                                        `deselect-all-text` = "Ninguno",
                                        `select-all-text` = "Todos",
                                        `none-selected-text` = "Sin selección"
                                   )
                              )
                         ),

                         # Filtro 4: inclusión o exclusión de ofertas.
                         # Marcado: incluye ofertas y precios regulares.
                         # Desmarcado: utiliza solamente precios regulares.
                         column(
                              width = 3,
                              tags$div(
                                   style = "margin-top: 25px;",
                                   checkboxInput(
                                        inputId = "tab1_incluirofertas_chk",
                                        label = "Incluir productos en oferta",
                                        value = TRUE
                                   )
                              )
                         )
                    )
               ),

               fluidRow(
                    column(
                         width = 12,
                         h4(
                              "Crecimiento porcentual semana a semana de productos seleccionados"
                         ),
                         plotlyOutput(
                              outputId = "tab1_grafico_crecimiento",
                              height = "500px"
                         )
                    )
               )
          ),

          # --------------------------------------------------------------------
          # TAB 2: VARIACIÓN POR BARRIO
          # --------------------------------------------------------------------
          tabPanel(
               "Variación por barrio",

               wellPanel(
                    fluidRow(

                         # Filtro 1: selección de un producto.
                         column(
                              width = 3,
                              pickerInput(
                                   inputId = "tab2_producto_cbx",
                                   label = "Seleccionar producto:",
                                   choices = c(),
                                   multiple = FALSE,
                                   options = list(
                                        `actions-box` = TRUE,
                                        `deselect-all-text` = "Ninguno",
                                        `select-all-text` = "Todos",
                                        `none-selected-text` = "Sin selección"
                                   )
                              )
                         ),

                         # Filtro 2: inclusión o exclusión de ofertas.
                         # Marcado: incluye ofertas y precios regulares.
                         # Desmarcado: utiliza solamente precios regulares.
                         column(
                              width = 3,
                              tags$div(
                                   style = "margin-top: 25px;",
                                   checkboxInput(
                                        inputId = "tab2_incluirofertas_chk",
                                        label = "Incluir productos en oferta",
                                        value = TRUE
                                   )
                              )
                         ),

                         # Filtro 3: período de análisis.
                         column(
                              width = 4,
                              dateRangeInput(
                                   inputId = "tab2_rango_fechas",
                                   label = "Período de análisis:",
                                   start = "2025-01-01",
                                   end = "2025-12-31",
                                   min = "2025-01-01",
                                   max = "2025-12-31",
                                   format = "yyyy-mm-dd",
                                   language = "es",
                                   separator = " a "
                              )
                         )
                    )
               ),

               fluidRow(

                    # Mapa de variación de precios por barrio.
                    column(
                         width = 8,
                         h4("Distribución geográfica"),
                         leafletOutput(
                              outputId = "tab2_mapa_resultados",
                              height = "500px"
                         )
                    ),

                    # Lista de barrios sin registros disponibles.
                    column(
                         width = 4,
                         h4("Barrios sin datos:"),
                         tags$div(
                              style = paste0(
                                   "height: 500px; ",
                                   "overflow-y: auto; ",
                                   "background-color: #f9f9f9; ",
                                   "padding: 10px; ",
                                   "border: 1px solid #ddd;"
                              ),
                              uiOutput(
                                   outputId = "tab2_lista_barrios_vacias"
                              )
                         )
                    )
               )
          )
     )
)
