# ==========================================
# 1. INTERFAZ DE USUARIO (UI)
# ==========================================

ui <- fluidPage(
     titlePanel("Análisis de datos de SIPC..."),
     
     # --- BARRA SUPERIOR DE FILTROS ---
     wellPanel(
          fluidRow(
               # Filtro 1: Buscar producto
               column(width = 3,
                      textInput("filtroProducto_txt",
                                "Buscar producto:",
                                value = "")
               ),
               
               # Filtro 2: Seleccionar productos
               column(width = 3,
                      pickerInput(
                           inputId = "producto_cbx",
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
                           inputId = "barrios_cbx",
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
                                    inputId = "incluirofertas_chk",
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
                 plotlyOutput("grafico_crecimiento", height = "450px")
          )
     )
)