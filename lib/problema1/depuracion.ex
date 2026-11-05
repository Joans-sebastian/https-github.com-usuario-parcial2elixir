defmodule Rutas.Depuracion do
  @moduledoc """
  **Validación previa con recursión: depurar la red** (problema 1).

  Antes de construir el grafo se recorren recursivamente los tramos válidos y
  se descartan:

  1. los **bucles**: tramos que salen y llegan al mismo centro (`A,A,...`);
  2. las **repeticiones** de la misma pareja en la misma dirección. Si cambian
     el tiempo o el costo, se conserva la **primera** aparición.

  Los tramos en dirección contraria (`A→B` y `B→A`) son distintos y se
  conservan los dos.

  Requisito 7: estas funciones son recursivas propias y no usan los módulos
  de colecciones ni de flujos. Solo usan `Map` como tabla de "ya visto" y
  `Lista.invertir/1` (también recursiva) para devolver el orden original.
  """

  @doc """
  Depura la lista de tramos válidos.

  Retorna `{conservados, descartes}`, donde `descartes` es una lista de
  `{tramo, motivo}`. Ambas listas mantienen el orden del archivo, y cada tramo
  conserva su número de línea física en `tramo.linea`.

  ## Ejemplo

      Rutas.Depuracion.depurar([ab_linea2, aa_linea8, ab_linea9])
      #=> {[ab_linea2],
      #    [{aa_linea8, "bucle: ..."}, {ab_linea9, "repetido: ..."}]}
  """
  def depurar(tramos), do: depurar(tramos, %{}, [], [])

  # Caso base: no quedan tramos. Se invierten los acumuladores.
  defp depurar([], _vistos, conservados, descartes) do
    {Lista.invertir(conservados), Lista.invertir(descartes)}
  end

  # Bucle: el patrón exige que origen y destino sean el MISMO valor `c`.
  defp depurar([%Tramo{origen: c, destino: c} = tramo | resto], vistos, conservados, descartes) do
    motivo = "bucle: el tramo sale y llega al mismo centro (#{c})"
    depurar(resto, vistos, conservados, [{tramo, motivo} | descartes])
  end

  # Tramo normal: se conserva solo si la pareja (origen, destino) no apareció antes.
  defp depurar([tramo | resto], vistos, conservados, descartes) do
    pareja = {tramo.origen, tramo.destino}

    case Map.fetch(vistos, pareja) do
      {:ok, linea_original} ->
        motivo =
          "repetido: la pareja #{tramo.origen} → #{tramo.destino} ya se definió en la " <>
            "línea #{linea_original}; se conserva la primera aparición"

        depurar(resto, vistos, conservados, [{tramo, motivo} | descartes])

      :error ->
        depurar(resto, Map.put(vistos, pareja, tramo.linea), [tramo | conservados], descartes)
    end
  end
end
