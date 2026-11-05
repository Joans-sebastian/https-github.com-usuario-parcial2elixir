defmodule Itinerario do
  @moduledoc """
  Un **itinerario simple**: la secuencia de `centros` recorridos (sin
  repetir), los `tramos` usados en orden, y los totales de `minutos` y `costo`.
  """

  defstruct centros: [], tramos: [], minutos: 0, costo: 0

  @doc """
  Construye un itinerario a partir del centro de origen y la lista de tramos
  recorridos, en orden. Suma tiempos y costos.

  ## Ejemplo

      Itinerario.desde_tramos("A", [tramo_a_b, tramo_b_d])
      #=> %Itinerario{centros: ["A", "B", "D"], minutos: 15, costo: 9, ...}
  """
  def desde_tramos(origen, tramos) do
    %Itinerario{
      centros: [origen | Enum.map(tramos, & &1.destino)],
      tramos: tramos,
      minutos: tramos |> Enum.map(& &1.minutos) |> Enum.sum(),
      costo: tramos |> Enum.map(& &1.costo) |> Enum.sum()
    }
  end

  @doc "Número de tramos del itinerario (criterio (a) del enunciado)."
  def numero_tramos(%Itinerario{tramos: tramos}), do: length(tramos)

  @doc ~S'Secuencia de centros, por ejemplo `"A → B → D"`.'
  def ruta(%Itinerario{centros: centros}), do: Enum.join(centros, " → ")

  @doc "Lista legible de los tramos usados, con su tiempo y costo."
  def detalle_tramos(%Itinerario{tramos: []}), do: "ninguno (origen y destino coinciden)"

  def detalle_tramos(%Itinerario{tramos: tramos}) do
    tramos
    |> Enum.map(&Tramo.describir/1)
    |> Enum.join(", ")
  end

  # "#{itinerario}" produce la línea del reporte, igual al formato del enunciado.
  defimpl String.Chars do
    def to_string(itinerario) do
      "#{Itinerario.ruta(itinerario)} | tramos: #{Itinerario.numero_tramos(itinerario)}" <>
        " | #{itinerario.minutos} min | costo: #{itinerario.costo}"
    end
  end
end
