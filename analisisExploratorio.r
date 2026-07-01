

vEst <- vDF_Main |> group_by(producto, barrio) |>
     summarise(
          Media = mean(precio, na.rm = TRUE),
          Mediana = median(precio, na.rm = TRUE),
          Desv_Estandar = sd(precio, na.rm = TRUE),
          Minimo = min(precio, na.rm = TRUE),
          Maximo = max(precio, na.rm = TRUE),
          Total_Registros = n())     