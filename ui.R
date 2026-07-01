# ==========================================
# 1. INTERFAZ DE USUARIO (UI)
# ==========================================

ui <- fluidPage(
     titlePanel("Análisis de datos de SIPC."),
     
     tabsetPanel(
          tabPanel("Modificación porcentual de precios", 
                   # --- BARRA SUPERIOR DE FILTROS ---
                   wellPanel(
                        fluidRow(
                             # Filtro 1: Buscar producto
                             column(width = 3,
                                    textInput("tab1_filtroProducto_txt",
                                              "Buscar producto:",
                                              value = "")
                             ),
                             
                             # Filtro 2: Seleccionar productos
                             column(width = 3,
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
                                         ))
                             ),
                             
                             # Filtro 3: Barrios
                             column(width = 3,
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
                                         ))
                             ),
                             
                             # Filtro 4: Ofertas (Agregamos un estilo para alinearlo verticalmente con los demás)
                             column(width = 3,
                                    tags$div(style = "margin-top: 25px;", 
                                             checkboxInput(
                                                  inputId = "tab1_incluirofertas_chk",
                                                  label = "Incluir productos en oferta",
                                                  value = TRUE)
                                    )
                             )
                        )
                   ),
                   
                   # --- ZONA DE RESULTADOS (Ocupa el 100% del ancho ahora) ---
                   fluidRow(
                        column(width = 12,
                               h4("Crecimiento Porcentual Semana a Semana de Productos Seleccionados"),
                               plotlyOutput("tab1_grafico_crecimiento", height = "500px")
                        )
                   )
          ),
          
          # Tab #2.
          tabPanel("Variación por barrio", 
                   # --- BARRA SUPERIOR DE FILTROS ---
                   wellPanel(
                        fluidRow(
                             # Filtro 1: Buscar producto
                             column(width = 3,
                                    textInput("tab2_filtroProducto_txt",
                                              "Buscar producto:",
                                              value = "")
                             ),
                             
                             # Filtro 2: Seleccionar productos
                             column(width = 3,
                                    pickerInput(
                                         inputId = "tab2_producto_cbx",
                                         label = "Seleccionar productos:",
                                         choices = c(),
                                         multiple = TRUE,
                                         options = list(
                                              `actions-box` = TRUE,
                                              `deselect-all-text` = "Ninguno",
                                              `select-all-text` = "Todos",
                                              `none-selected-text` = "Sin selección"
                                         ))
                             ),
                             
                             # Filtro 3: Ofertas (Agregamos un estilo para alinearlo verticalmente con los demás)
                             column(width = 3,
                                    tags$div(style = "margin-top: 25px;", 
                                             checkboxInput(
                                                  inputId = "tab2_incluirofertas_chk",
                                                  label = "Incluir productos en oferta",
                                                  value = TRUE)
                                    )
                             )
                        )
                   ),
                   
                   # --- ZONA DE RESULTADOS (Ocupa el 100% del ancho ahora) ---
                   fluidRow(
                        column(width = 12,
                               h4("Distribución Geográfica"),
                               leafletOutput("tab2_mapa_resultados", height = "500px", width="750px") # Render del mapa
                        )
                   )
          )
     )
)     

