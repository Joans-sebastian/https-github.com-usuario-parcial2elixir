defmodule Region do
  @moduledoc """
  Una **región**: grupo de casillas con el mismo símbolo conectadas en
  horizontal o vertical.

  - `id`: número asignado según la primera casilla encontrada (orden por filas).
  - `simbolo`: símbolo del mapa.
  - `celdas`: lista ordenada de coordenadas `{fila, columna}` (desde 0).
  - `area`: cantidad de casillas.
  - `perimetro`: lados que tocan el borde o una casilla de otro símbolo.
  - `desde` / `hasta`: esquinas de la caja envolvente.
  """

  defstruct id: 0, simbolo: "", celdas: [], area: 0, perimetro: 0, desde: {0, 0}, hasta: {0, 0}

  @doc """
  Crea la región a partir de sus casillas y calcula área, perímetro y caja.

  `celdas_mapa` es el mapa `%{{fila, columna} => simbolo}` completo.
  """
  def nueva(id, simbolo, celdas, celdas_mapa) do
    ordenadas = Enum.sort(celdas)
    filas = Enum.map(ordenadas, fn {fila, _columna} -> fila end)
    columnas = Enum.map(ordenadas, fn {_fila, columna} -> columna end)

    %Region{
      id: id,
      simbolo: simbolo,
      celdas: ordenadas,
      area: length(ordenadas),
      perimetro: perimetro(ordenadas, simbolo, celdas_mapa),
      desde: {Enum.min(filas), Enum.min(columnas)},
      hasta: {Enum.max(filas), Enum.max(columnas)}
    }
  end

  @doc """
  Las 4 casillas vecinas (arriba, abajo, izquierda, derecha). Las diagonales
  no cuentan. Puede devolver coordenadas fuera del mapa; quien la usa lo tiene
  en cuenta (`Map.get` da `nil` fuera del mapa).
  """
  def vecinos({fila, columna}) do
    [{fila - 1, columna}, {fila + 1, columna}, {fila, columna - 1}, {fila, columna + 1}]
  end

  # Cada lado de una casilla suma 1 si del otro lado hay borde (nil) o un símbolo
  # distinto (incluido el fondo ".").
  defp perimetro(celdas, simbolo, celdas_mapa) do
    celdas
    |> Enum.flat_map(&vecinos/1)
    |> Enum.count(&(Map.get(celdas_mapa, &1) != simbolo))
  end

  @doc ~S'Línea del CSV de salida: `"1;A;3;8;{0,0};{1,1}"`.'
  def a_csv(%Region{} = r) do
    "#{r.id};#{r.simbolo};#{r.area};#{r.perimetro};#{coordenada(r.desde)};#{coordenada(r.hasta)}"
  end

  @doc ~S'Coordenada con el formato del enunciado: `"{2,0}"`.'
  def coordenada({fila, columna}), do: "{#{fila},#{columna}}"
end
