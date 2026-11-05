defmodule Rutas.Alcance do
  @moduledoc """
  **Stream infinito de centros alcanzables** (problema 1).

  - Paso 0: solo el origen.
  - Paso k+1: el conjunto del paso k más todos los destinos de los tramos que
    salen de los centros de ese conjunto.

  ## ¿Por qué converge si el Stream es infinito?

  1. Los conjuntos **solo crecen**: el paso k+1 contiene al paso k (se hace
     una unión).
  2. Están **acotados**: nunca pueden tener más centros que la red, que es finita.

  Una sucesión que crece y está acotada no puede crecer para siempre: después
  de, como mucho, *n* pasos (con *n* el número de centros) un paso repite el
  conjunto anterior. Desde ese momento todos los pasos son iguales (punto
  fijo), porque expandir el mismo conjunto da el mismo resultado.

  El Stream (`Stream.iterate/2`) **describe** la sucesión infinita, pero es
  perezoso: no calcula ningún paso hasta que se le pide. `Enum.reduce_while/3`
  pide pasos uno a uno y se detiene (`:halt`) en el primer estado repetido,
  así que solo se calculan los pasos necesarios.
  """

  @doc """
  El Stream infinito de conjuntos alcanzables desde `origen`.

  ## Ejemplo (red del enunciado)

      Rutas.Alcance.secuencia(grafo, "A") |> Enum.take(4)
      #=> [MapSet<["A"]>, MapSet<["A","B","C"]>, MapSet<["A","B","C","D"]>, MapSet<["A","B","C","D"]>]
  """
  def secuencia(grafo, origen) do
    Stream.iterate(MapSet.new([origen]), &expandir(&1, grafo))
  end

  @doc """
  Un paso de la sucesión: agrega al conjunto los destinos de todos los tramos
  que salen de sus centros.
  """
  def expandir(conjunto, grafo) do
    conjunto
    |> Enum.flat_map(&Map.get(grafo, &1, []))
    |> Enum.map(& &1.destino)
    |> MapSet.new()
    |> MapSet.union(conjunto)
  end

  @doc """
  Consume el Stream infinito hasta el primer estado repetido consecutivo.

  Retorna `{estados_distintos, paso_estable}`:

  - `estados_distintos`: los conjuntos de los pasos 0..m, en orden.
  - `paso_estable`: el paso m donde se estabiliza (el paso m+1 lo repite).

  Solo se calculan m+2 elementos del Stream (pasos 0..m+1).

  ## Ejemplo (red del enunciado)

      Rutas.Alcance.hasta_estabilizar(grafo, "A")
      #=> {[MapSet<["A"]>, MapSet<["A","B","C"]>, MapSet<["A","B","C","D"]>], 2}
  """
  def hasta_estabilizar(grafo, origen) do
    grafo
    |> secuencia(origen)
    |> Stream.with_index()
    |> Enum.reduce_while([], &comparar_con_anterior/2)
  end

  # Primer elemento: aún no hay con qué comparar.
  defp comparar_con_anterior({estado, _paso}, []), do: {:cont, [estado]}

  # El acumulador guarda los estados al revés: el anterior es la cabeza.
  defp comparar_con_anterior({estado, paso}, [anterior | _] = estados) do
    if MapSet.equal?(estado, anterior) do
      {:halt, {Enum.reverse(estados), paso - 1}}
    else
      {:cont, [estado | estados]}
    end
  end

  @doc ~S'Representación ordenada de un conjunto, por ejemplo `"{A, B, C}"`.'
  def formatear(conjunto) do
    texto =
      conjunto
      |> MapSet.to_list()
      |> Util2.ordenar()
      |> Enum.join(", ")

    "{#{texto}}"
  end
end
