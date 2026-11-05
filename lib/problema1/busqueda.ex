defmodule Rutas.Busqueda do
  @moduledoc """
  Construcción del grafo dirigido y **búsqueda recursiva** de todos los
  itinerarios simples entre dos centros (problema 1).

  El grafo es un mapa `%{centro => [tramos que salen de ese centro]}`. La
  lista de cada centro conserva el orden del archivo, y por eso los
  itinerarios salen en el mismo orden del enunciado.
  """

  @doc """
  Arma el grafo (lista de adyacencia) a partir de los tramos depurados.

  ## Ejemplo

      Rutas.Busqueda.construir_grafo(tramos)
      #=> %{"A" => [A→B, A→C], "B" => [B→D, B→C], "C" => [C→D, C→B]}
  """
  def construir_grafo(tramos), do: Enum.group_by(tramos, & &1.origen)

  @doc "Conjunto (`MapSet`) de todos los centros que aparecen en la red."
  def centros(tramos) do
    tramos
    |> Enum.flat_map(&[&1.origen, &1.destino])
    |> MapSet.new()
  end

  @doc """
  Encuentra **todos** los itinerarios simples de `origen` a `destino`.

  Es un recorrido en profundidad con *backtracking*: desde el centro actual se
  prueba cada tramo de salida cuyo destino no se haya visitado. Como los datos
  son inmutables, "deshacer" una elección es automático: cada llamada
  recursiva recibe su propia copia del conjunto `visitados`.

  ## Ejemplo (red del enunciado)

      Rutas.Busqueda.itinerarios(grafo, "A", "D") |> Enum.map(&Itinerario.ruta/1)
      #=> ["A → B → D", "A → B → C → D", "A → C → D", "A → C → B → D"]
  """
  def itinerarios(grafo, origen, destino) do
    grafo
    |> explorar(origen, destino, MapSet.new([origen]), [])
    |> Enum.map(&Itinerario.desde_tramos(origen, &1))
  end

  # Caso base: llegamos al destino. El camino se acumuló al revés.
  defp explorar(_grafo, destino, destino, _visitados, camino_al_reves) do
    [Enum.reverse(camino_al_reves)]
  end

  # Caso recursivo: se prueba cada tramo de salida hacia un centro no visitado.
  # Si un centro no tiene salidas, Map.get devuelve [] y la rama no aporta caminos.
  defp explorar(grafo, actual, destino, visitados, camino_al_reves) do
    grafo
    |> Map.get(actual, [])
    |> Enum.reject(&MapSet.member?(visitados, &1.destino))
    |> Enum.flat_map(fn tramo ->
      explorar(
        grafo,
        tramo.destino,
        destino,
        MapSet.put(visitados, tramo.destino),
        [tramo | camino_al_reves]
      )
    end)
  end

  @doc """
  Para una lista de itinerarios, retorna los **números** (empezando en 1) de
  los que minimizan cada criterio, conservando todos los empates:

  - `:tramos`: menor número de tramos,
  - `:minutos`: menor tiempo,
  - `:costo`: menor costo.

  ## Ejemplo (red del enunciado, consulta A → D)

      Rutas.Busqueda.optimos(itinerarios)
      #=> %{tramos: [1, 3], minutos: [1], costo: [3]}
  """
  def optimos([]), do: %{tramos: [], minutos: [], costo: []}

  def optimos(itinerarios) do
    numerados = Enum.with_index(itinerarios, 1)

    %{
      tramos: mejores(numerados, &Itinerario.numero_tramos/1),
      minutos: mejores(numerados, & &1.minutos),
      costo: mejores(numerados, & &1.costo)
    }
  end

  # Calcula el mínimo del criterio y filtra todos los itinerarios que lo alcanzan
  # (así se conservan los empates). Reutiliza Util2.aplicar_filtro/2 del curso.
  defp mejores(numerados, criterio) do
    minimo =
      numerados
      |> Enum.map(fn {itinerario, _numero} -> criterio.(itinerario) end)
      |> Enum.min()

    numerados
    |> Util2.aplicar_filtro(fn {itinerario, _numero} -> criterio.(itinerario) == minimo end)
    |> Enum.map(fn {_itinerario, numero} -> numero end)
  end
end
