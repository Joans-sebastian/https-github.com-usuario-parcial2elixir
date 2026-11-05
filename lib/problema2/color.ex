defmodule Color do
  @moduledoc """
  Un color de la paleta (`paleta.csv`): el `simbolo` del mapa, su `nombre`
  y el color `hex` con el que se dibuja. `linea` es la línea física de origen.
  """

  defstruct simbolo: "", nombre: "", hex: "", linea: 0

  @doc """
  Convierte una línea de `paleta.csv` (`simbolo,nombre,color_hex`) en un
  `%Color{}`. Recibe la tupla `{numero_linea, texto}`.

  Aquí solo se revisa la **forma** (3 campos, símbolo no vacío). El formato
  `#RRGGBB`, los repetidos y la existencia de `.` los revisa la validación
  recursiva (`Mapa.Validacion`).

  ## Ejemplos

      Color.parse({1, "A,agua,#2563EB"})
      #=> {:ok, %Color{simbolo: "A", nombre: "agua", hex: "#2563EB", linea: 1}}

      Color.parse({2, "A,agua"})
      #=> {:error, "se esperaban 3 campos (simbolo,nombre,color_hex) y hay 2"}
  """
  def parse({numero_linea, texto}) do
    case texto |> String.split(",") |> Enum.map(&String.trim/1) do
      ["", _nombre, _hex] ->
        {:error, "el símbolo está vacío"}

      [simbolo, nombre, hex] ->
        {:ok, %Color{simbolo: simbolo, nombre: nombre, hex: hex, linea: numero_linea}}

      campos ->
        {:error, "se esperaban 3 campos (simbolo,nombre,color_hex) y hay #{length(campos)}"}
    end
  end

  @doc """
  Construye la tabla `%{simbolo => %Color{}}` a partir de las líneas ya
  parseadas. Si un símbolo se repite, se queda la primera aparición.
  Se usa solo cuando la validación pasó.
  """
  def tabla(colores_parseados) do
    Enum.reduce(colores_parseados, %{}, fn
      {_linea, {:ok, color}}, tabla -> Map.put_new(tabla, color.simbolo, color)
      {_linea, {:error, _motivo}}, tabla -> tabla
    end)
  end
end
