defmodule Mapa.Regiones do
  @moduledoc """
  **Identificación recursiva de regiones** (problema 2).

  Usa las dos funciones recursivas que pide el enunciado:

  - `recorrer_casillas/5`: recorre todas las casillas en orden (fila por fila,
    columna por columna) y, cuando encuentra una casilla que no es fondo y aún
    no tiene región, abre una región nueva con el siguiente ID.
  - `explorar/5`: desde una casilla, visita recursivamente los 4 vecinos con
    el mismo símbolo (relleno por inundación, *flood fill*).

  El conjunto `asignadas` se pasa de llamada en llamada: así ninguna casilla
  se recorre dos veces.
  """

  @doc """
  Convierte las filas leídas (`[{linea, [simbolos]}]`) en la estructura del
  mapa:

      %{celdas: %{{fila, columna} => simbolo}, filas: n, columnas: m}
  """
  def construir_mapa([{_linea, primera} | _] = filas) do
    celdas =
      for {{_linea, simbolos}, fila} <- Enum.with_index(filas),
          {simbolo, columna} <- Enum.with_index(simbolos),
          into: %{},
          do: {{fila, columna}, simbolo}

    %{celdas: celdas, filas: length(filas), columnas: length(primera)}
  end

  @doc "Todas las coordenadas en orden: fila ascendente y luego columna ascendente."
  def posiciones(%{filas: filas, columnas: columnas}) do
    for fila <- 0..(filas - 1)//1, columna <- 0..(columnas - 1)//1, do: {fila, columna}
  end

  @doc """
  Encuentra todas las regiones del mapa, con ID desde 1 en orden de aparición.

  ## Ejemplo (mapa del enunciado)

      Mapa.Regiones.encontrar(mapa) |> Enum.map(&Region.a_csv/1)
      #=> ["1;A;3;8;{0,0};{1,1}", "2;B;3;8;{0,3};{1,4}",
      #    "3;C;5;12;{2,0};{4,2}", "4;B;3;8;{3,3};{4,4}"]
  """
  def encontrar(mapa) do
    mapa
    |> posiciones()
    |> recorrer_casillas(mapa.celdas, MapSet.new(), 1, [])
  end

  # Caso base: no quedan casillas por revisar.
  defp recorrer_casillas([], _celdas, _asignadas, _siguiente_id, regiones) do
    Enum.reverse(regiones)
  end

  defp recorrer_casillas([posicion | resto], celdas, asignadas, siguiente_id, regiones) do
    simbolo = Map.fetch!(celdas, posicion)

    if simbolo == "." or MapSet.member?(asignadas, posicion) do
      # Fondo o casilla ya asignada: se salta.
      recorrer_casillas(resto, celdas, asignadas, siguiente_id, regiones)
    else
      # Casilla nueva: se explora toda su región.
      {casillas_region, asignadas} =
        explorar(posicion, simbolo, celdas, MapSet.put(asignadas, posicion), [])

      region = Region.nueva(siguiente_id, simbolo, casillas_region, celdas)
      recorrer_casillas(resto, celdas, asignadas, siguiente_id + 1, [region | regiones])
    end
  end

  # Visita la casilla `posicion` (ya marcada como asignada) y luego sus vecinos.
  # Retorna {casillas de la región, asignadas actualizadas}.
  defp explorar(posicion, simbolo, celdas, asignadas, region) do
    posicion
    |> Region.vecinos()
    |> explorar_vecinos(simbolo, celdas, asignadas, [posicion | region])
  end

  defp explorar_vecinos([], _simbolo, _celdas, asignadas, region), do: {region, asignadas}

  defp explorar_vecinos([vecino | resto], simbolo, celdas, asignadas, region) do
    # Map.get devuelve nil fuera del mapa, así que no hace falta revisar bordes.
    if Map.get(celdas, vecino) == simbolo and not MapSet.member?(asignadas, vecino) do
      {region, asignadas} =
        explorar(vecino, simbolo, celdas, MapSet.put(asignadas, vecino), region)

      explorar_vecinos(resto, simbolo, celdas, asignadas, region)
    else
      explorar_vecinos(resto, simbolo, celdas, asignadas, region)
    end
  end
end
