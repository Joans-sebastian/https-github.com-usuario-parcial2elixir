defmodule Problema2 do
  @moduledoc """
  **Problema 2: regiones de un mapa de colores y exportación SVG.**
  Programa principal.

  Flujo completo (descomposición del problema):

  1. Verificar que existan `mapa.txt` y `paleta.csv`.
  2. Leer ambos archivos de forma perezosa (Stream) y, ya consumidos,
     guardarlos en listas.
  3. Validar recursivamente (`Mapa.Validacion`) → `validacion_mapa.txt`.
     Si hay problemas, se detiene sin calcular regiones ni SVG.
  4. Construir el mapa y encontrar las regiones (`Mapa.Regiones`).
  5. Escribir `regiones.csv`, `mapa_regiones.svg` y `resumen_regiones.txt`.
  6. Mostrar el resumen en pantalla.

  ## Uso

      mix run problema2.exs datos/problema2/ejemplo
  """

  alias Mapa.{Regiones, Svg, Validacion}

  @entrada_por_defecto "datos/problema2/ejemplo"
  @salidas_calculadas ["regiones.csv", "mapa_regiones.svg", "resumen_regiones.txt"]

  @doc """
  Ejecuta el problema 2 con los archivos de `dir_entrada` y deja los resultados
  en `dir_salida` (por defecto `salidas/problema2/<nombre del caso>`).

  Retorna `{:ok, regiones}`, `{:error, problemas}` o
  `{:error, {:faltan_archivos, rutas}}`.
  """
  def main(dir_entrada \\ @entrada_por_defecto, dir_salida \\ nil) do
    dir_salida = dir_salida || Path.join("salidas/problema2", Path.basename(dir_entrada))
    ruta_mapa = Path.join(dir_entrada, "mapa.txt")
    ruta_paleta = Path.join(dir_entrada, "paleta.csv")

    Util2.mostrar("\n=== Problema 2: regiones del mapa (#{dir_entrada}) ===", :mensaje)

    case Entrada.verificar_archivos([ruta_mapa, ruta_paleta]) do
      :ok ->
        ejecutar(ruta_mapa, ruta_paleta, dir_salida)

      {:error, faltantes} ->
        Enum.each(faltantes, &Util2.mostrar("Falta el archivo requerido: #{&1}", :error))
        {:error, {:faltan_archivos, faltantes}}
    end
  end

  defp ejecutar(ruta_mapa, ruta_paleta, dir_salida) do
    filas = leer_mapa(ruta_mapa)
    colores = leer_paleta(ruta_paleta)

    problemas = Validacion.validar(filas, colores)
    Salida.escribir(Path.join(dir_salida, "validacion_mapa.txt"), lineas_validacion(problemas))

    case problemas do
      [] ->
        calcular(filas, colores, dir_salida)

      _ ->
        # Se borran resultados viejos para que no se confundan con esta ejecución.
        Salida.eliminar(Enum.map(@salidas_calculadas, &Path.join(dir_salida, &1)))

        Util2.mostrar(
          "#{cantidad_problemas(problemas)} (ver validacion_mapa.txt); " <>
            "no se calculan regiones ni SVG:",
          :error
        )

        Enum.each(problemas, &Util2.mostrar("  - #{&1}", :error))
        {:error, problemas}
    end
  end

  # Lectura perezosa: cada línea útil se separa en símbolos; luego se consume.
  defp leer_mapa(ruta) do
    ruta
    |> Entrada.lineas_utiles()
    |> Stream.map(fn {numero, texto} -> {numero, String.split(texto)} end)
    |> Enum.to_list()
  end

  defp leer_paleta(ruta) do
    ruta
    |> Entrada.lineas_utiles()
    |> Stream.map(fn {numero, _texto} = linea -> {numero, Color.parse(linea)} end)
    |> Enum.to_list()
  end

  defp calcular(filas, colores, dir_salida) do
    paleta = Color.tabla(colores)
    mapa = Regiones.construir_mapa(filas)
    regiones = Regiones.encontrar(mapa)

    Salida.escribir(
      Path.join(dir_salida, "regiones.csv"),
      Stream.concat([
        ["id;simbolo;area;perimetro;desde;hasta"],
        Stream.map(regiones, &Region.a_csv/1)
      ])
    )

    Svg.generar(Path.join(dir_salida, "mapa_regiones.svg"), mapa, regiones, paleta)

    resumen = lineas_resumen(regiones, paleta)
    Salida.escribir(Path.join(dir_salida, "resumen_regiones.txt"), resumen)
    Enum.each(resumen, &Util2.mostrar(&1, :mensaje))
    Util2.mostrar("Archivos generados en #{dir_salida}", :mensaje)
    {:ok, regiones}
  end

  # ---------------------------------------------------------------------------
  # Formato de reportes
  # ---------------------------------------------------------------------------

  defp lineas_validacion([]) do
    ["Validación correcta: mapa.txt y paleta.csv no tienen problemas."]
  end

  defp lineas_validacion(problemas) do
    ["#{cantidad_problemas(problemas)}:"] ++
      Util2.convertir_coleccion_mensaje(problemas, &" - #{&1}")
  end

  defp cantidad_problemas([_unico]), do: "Se encontró 1 problema"
  defp cantidad_problemas(problemas), do: "Se encontraron #{length(problemas)} problemas"

  defp lineas_resumen(regiones, paleta) do
    [
      "Número de regiones: #{length(regiones)}",
      maximos("Mayor área", {"casilla", "casillas"}, regiones, & &1.area, paleta),
      maximos("Mayor perímetro", {"lado", "lados"}, regiones, & &1.perimetro, paleta)
    ]
  end

  defp maximos(titulo, _unidades, [], _criterio, _paleta) do
    "#{titulo}: no hay regiones (el mapa solo tiene fondo)"
  end

  # Busca el valor máximo y conserva todas las regiones empatadas.
  defp maximos(titulo, {singular, plural}, regiones, criterio, paleta) do
    maximo = regiones |> Enum.map(criterio) |> Enum.max()
    unidad = if maximo == 1, do: singular, else: plural

    empatadas =
      regiones
      |> Util2.aplicar_filtro(&(criterio.(&1) == maximo))
      |> Util2.ordenar(:asc, & &1.id)
      |> Enum.map(&"región #{&1.id} (#{&1.simbolo}, #{paleta[&1.simbolo].nombre})")
      |> Enum.join(", ")

    "#{titulo}: #{maximo} #{unidad} → #{empatadas}"
  end
end
