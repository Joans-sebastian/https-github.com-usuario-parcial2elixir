defmodule Tramo do
  @moduledoc """
  Un **tramo** dirigido de la red de distribución: va de `origen` a `destino`,
  tarda `minutos` y cuesta `costo`.

  Además de los cuatro datos del tramo, el struct conserva de dónde salió:

  - `linea`: la línea física de `tramos.csv`;
  - `contenido`: el texto original de esa línea, tal como estaba escrito.

  Así la depuración puede reportar la línea física, el contenido y el motivo
  de cada descarte, como pide el enunciado.
  """

  defstruct origen: "", destino: "", minutos: 0, costo: 0, linea: 0, contenido: ""

  @doc """
  Convierte una línea de `tramos.csv` en un `%Tramo{}`.

  Acepta el texto solo o la tupla `{numero_linea, texto}` que produce
  `Entrada.lineas_utiles/1`; en ese caso el número queda guardado en el struct.
  En los dos casos el texto original queda en el campo `contenido`.

  Retorna `{:ok, tramo}` o `{:error, motivo}`.

  ## Ejemplos

      Tramo.parse("A,B,8,5")
      #=> {:ok, %Tramo{origen: "A", destino: "B", minutos: 8, costo: 5, linea: 0, contenido: "A,B,8,5"}}

      Tramo.parse({2, "A, B, 8, 5"})
      #=> {:ok, %Tramo{origen: "A", destino: "B", minutos: 8, costo: 5, linea: 2, contenido: "A, B, 8, 5"}}

      Tramo.parse("A,B,ocho,5")
      #=> {:error, "minutos: 'ocho' no es un número entero"}
  """
  def parse({numero_linea, texto}) do
    case parse(texto) do
      {:ok, %Tramo{} = tramo} -> {:ok, %Tramo{tramo | linea: numero_linea}}
      error -> error
    end
  end

  def parse(texto) when is_binary(texto) do
    campos =
      texto
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    case campos do
      [origen, destino, minutos, costo] ->
        with :ok <- validar_centro(origen, "origen"),
             :ok <- validar_centro(destino, "destino"),
             {:ok, minutos} <- entero_positivo(minutos, "minutos"),
             {:ok, costo} <- entero_positivo(costo, "costo") do
          {:ok,
           %Tramo{
             origen: origen,
             destino: destino,
             minutos: minutos,
             costo: costo,
             contenido: texto
           }}
        end

      _ ->
        {:error, "se esperaban 4 campos (origen,destino,minutos,costo) y hay #{length(campos)}"}
    end
  end

  @doc """
  Descripción corta del tramo para los reportes.

  ## Ejemplo

      Tramo.describir(%Tramo{origen: "A", destino: "B", minutos: 8, costo: 5})
      #=> "A→B (8 min, costo 5)"
  """
  def describir(%Tramo{origen: o, destino: d, minutos: m, costo: c}) do
    "#{o}→#{d} (#{m} min, costo #{c})"
  end

  # --- Validaciones de cada campo -------------------------------------------

  defp validar_centro("", campo), do: {:error, "el #{campo} está vacío"}
  defp validar_centro(_centro, _campo), do: :ok

  # Integer.parse/1 devuelve {numero, resto}; solo es válido si no sobra texto.
  defp entero_positivo(texto, campo) do
    case Integer.parse(texto) do
      {numero, ""} when numero > 0 -> {:ok, numero}
      {numero, ""} -> {:error, "#{campo} debe ser un entero positivo y es #{numero}"}
      _ -> {:error, "#{campo}: '#{texto}' no es un número entero"}
    end
  end

  # Permite usar "#{tramo}" o to_string(tramo): reconstruye la línea CSV.
  defimpl String.Chars do
    def to_string(%Tramo{origen: o, destino: d, minutos: m, costo: c}) do
      "#{o},#{d},#{m},#{c}"
    end
  end
end
