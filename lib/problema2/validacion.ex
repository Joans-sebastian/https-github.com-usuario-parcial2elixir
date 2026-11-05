defmodule Mapa.Validacion do
  @moduledoc """
  **Validación previa con recursión: mapa y paleta** (problema 2).

  Revisa, con funciones recursivas propias (requisito 7: sin los módulos de
  colecciones ni de flujos):

  - Paleta: cada línea con 3 campos, símbolo no vacío, color con la forma
    `#RRGGBB`, sin símbolos repetidos, y que exista el símbolo `.` (fondo).
  - Mapa: que tenga filas, que ninguna fila esté vacía, que todas tengan la
    misma longitud que la fila 0, y que cada símbolo esté en la paleta.

  Reporta **todos** los problemas (no se detiene en el primero), indicando
  línea física, fila y columna (desde 0). Si hay alguno, el programa no
  calcula regiones ni SVG.
  """

  @doc """
  Valida el mapa y la paleta.

  - `filas`: lista de `{numero_linea, [simbolos]}` leída de `mapa.txt`.
  - `colores`: lista de `{numero_linea, {:ok, %Color{}} | {:error, motivo}}`.

  Retorna la lista de problemas (vacía si todo está bien).
  """
  def validar(filas, colores) do
    {tabla, problemas_paleta} = validar_paleta(colores, %{}, [])
    problemas_fondo = validar_fondo(tabla)
    problemas_mapa = validar_mapa(filas, tabla)
    problemas_paleta ++ problemas_fondo ++ problemas_mapa
  end

  # ---------------------------------------------------------------------------
  # Paleta
  # ---------------------------------------------------------------------------

  # Recorre las líneas de la paleta construyendo la tabla simbolo => color.
  defp validar_paleta([], tabla, problemas), do: {tabla, Lista.invertir(problemas)}

  defp validar_paleta([{linea, {:error, motivo}} | resto], tabla, problemas) do
    validar_paleta(resto, tabla, ["paleta.csv línea #{linea}: #{motivo}" | problemas])
  end

  defp validar_paleta([{linea, {:ok, color}} | resto], tabla, problemas) do
    problemas =
      case Map.fetch(tabla, color.simbolo) do
        {:ok, anterior} ->
          [
            "paleta.csv línea #{linea}: el símbolo '#{color.simbolo}' está repetido " <>
              "(ya se definió en la línea #{anterior.linea})"
            | problemas
          ]

        :error ->
          problemas
      end

    problemas =
      if hex_valido?(color.hex) do
        problemas
      else
        [
          "paleta.csv línea #{linea}: el color '#{color.hex}' del símbolo '#{color.simbolo}' " <>
            "no tiene la forma #RRGGBB"
          | problemas
        ]
      end

    validar_paleta(resto, Map.put_new(tabla, color.simbolo, color), problemas)
  end

  defp validar_fondo(tabla) do
    if Map.has_key?(tabla, ".") do
      []
    else
      ["paleta.csv: falta declarar el símbolo '.' (fondo)"]
    end
  end

  @doc """
  Verifica recursivamente que un texto tenga la forma `#RRGGBB`.

  ## Ejemplos

      Mapa.Validacion.hex_valido?("#2563EB") #=> true
      Mapa.Validacion.hex_valido?("#25G3EB") #=> false
      Mapa.Validacion.hex_valido?("2563EB")  #=> false
  """
  def hex_valido?("#" <> digitos) when byte_size(digitos) == 6 do
    digitos_hex?(String.to_charlist(digitos))
  end

  def hex_valido?(_texto), do: false

  defp digitos_hex?([]), do: true

  defp digitos_hex?([caracter | resto])
       when caracter in ?0..?9 or caracter in ?a..?f or caracter in ?A..?F do
    digitos_hex?(resto)
  end

  defp digitos_hex?(_caracteres), do: false

  # ---------------------------------------------------------------------------
  # Mapa
  # ---------------------------------------------------------------------------

  defp validar_mapa([], _tabla) do
    ["mapa.txt: el mapa no tiene filas (archivo vacío o solo comentarios)"]
  end

  # El ancho esperado es el de la fila 0.
  defp validar_mapa([{_linea, primera} | _resto] = filas, tabla) do
    validar_filas(filas, Lista.contar(primera), 0, tabla, [])
  end

  defp validar_filas([], _ancho, _fila, _tabla, problemas), do: Lista.invertir(problemas)

  defp validar_filas([{linea, simbolos} | resto], ancho, fila, tabla, problemas) do
    columnas = Lista.contar(simbolos)
    ubicacion = "mapa.txt línea #{linea} (fila #{fila})"

    problemas =
      cond do
        columnas == 0 ->
          ["#{ubicacion}: la fila está vacía" | problemas]

        columnas != ancho ->
          [
            "#{ubicacion}: tiene #{columnas} columnas y se esperaban #{ancho} (como la fila 0)"
            | problemas
          ]

        true ->
          problemas
      end

    problemas = validar_simbolos(simbolos, ubicacion, 0, tabla, problemas)
    validar_filas(resto, ancho, fila + 1, tabla, problemas)
  end

  defp validar_simbolos([], _ubicacion, _columna, _tabla, problemas), do: problemas

  # El fondo "." no se reporta casilla por casilla: si falta, validar_fondo/1 ya
  # lo informó una vez.
  defp validar_simbolos([simbolo | resto], ubicacion, columna, tabla, problemas) do
    problemas =
      if simbolo == "." or Map.has_key?(tabla, simbolo) do
        problemas
      else
        [
          "#{ubicacion}, columna #{columna}: el símbolo '#{simbolo}' no está definido en paleta.csv"
          | problemas
        ]
      end

    validar_simbolos(resto, ubicacion, columna + 1, tabla, problemas)
  end
end
