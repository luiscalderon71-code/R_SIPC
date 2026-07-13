# ==========================================
# 1. INTERFAZ DE USUARIO (UI)
# ==========================================

ui <- fluidPage(

     # Esto aplica un tema elegante y profesional (puedes probar también "minty" o "lux")
     theme = bs_theme(version = 5, bootswatch = "minty"), 
     
     titlePanel(tags$div(
          tags$small("Análisis SIPC: Monitor de variación de precios en Montevideo")
     )),
     
     tabsetPanel(
          tabPanel("Modificación porcentual de precios", 
                   # --- BARRA SUPERIOR DE FILTROS ---
                   wellPanel(
                        fluidRow(
                             # Filtro 1: Buscar producto
                             column(width = 2,
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
                               h4("Crecimiento porcentual semana a semana de productos seleccionados"),
                               plotlyOutput("tab1_grafico_crecimiento", height = "500px")
                        )
                   )
          ),
          
          # Tab #2.
          tabPanel("Variación por barrio", 
                   # --- BARRA SUPERIOR DE FILTROS ---
                   wellPanel(
                        fluidRow(

                             # Filtro 1: Seleccionar productos
                             column(width = 3,
                                    pickerInput(
                                         inputId = "tab2_producto_cbx",
                                         label = "Seleccionar productos:",
                                         choices = c(),
                                         multiple = FALSE,
                                         options = list(
                                              `actions-box` = TRUE,
                                              `deselect-all-text` = "Ninguno",
                                              `select-all-text` = "Todos",
                                              `none-selected-text` = "Sin selección"
                                         ))
                             ),
                             
                             # Filtro 2: Ofertas (Agregamos un estilo para alinearlo verticalmente con los demás)
                             column(width = 3,
                                    tags$div(style = "margin-top: 25px;", 
                                             checkboxInput(
                                                  inputId = "tab2_incluirofertas_chk",
                                                  label = "Incluir productos en oferta",
                                                  value = TRUE)
                                    )
                             ),

                             # Filtro 3: Rango de fechas.
                             column(width = 4,
                                    dateRangeInput("tab2_rango_fechas", 
                                                   "Periodo de análisis:",
                                                   start = "2025-01-01", # Ajusta según tu fecha mínima real
                                                   end = "2025-12-31",   # Ajusta según tu fecha máxima real
                                                   min = "2025-01-01", 
                                                   max = "2025-12-31",
                                                   format = "yyyy-mm-dd",
                                                   language = "es",
                                                   separator = " a ")
                             )                           
                        )
                   ),
                   
                   # --- ZONA DE RESULTADOS (Ocupa el 100% del ancho ahora) ---
                   fluidRow(
                        # Columna Izquierda: Mapa (ancho 8)
                        column(width = 8,
                               h4("Distribución Geográfica"),
                               leafletOutput("tab2_mapa_resultados", height = "500px")
                        ),
                        
                        # Columna Derecha: Lista (ancho 4)
                        column(width = 4,
                               h4("Barrios sin datos:"),
                               tags$div(style = "height: 500px; overflow-y: auto; background-color: #f9f9f9; padding: 10px; border: 1px solid #ddd;",
                                        uiOutput("tab2_lista_barrios_vacias") # Aquí va el ID del output
                               )
                        )
                   )
          )
     )
)     

