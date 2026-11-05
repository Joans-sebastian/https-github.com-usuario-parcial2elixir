ExUnit.start()

defmodule Apoyo do
  @moduledoc "Funciones de apoyo para las pruebas."

  @doc "Carpeta temporal única para que cada prueba escriba sus salidas."
  def carpeta_temporal(nombre) do
    ruta =
      Path.join(System.tmp_dir!(), "parcial2_#{nombre}_#{System.unique_integer([:positive])}")

    File.rm_rf!(ruta)
    ruta
  end

  @doc "Escribe un archivo de entrada de prueba (crea la carpeta)."
  def escribir(carpeta, nombre, contenido) do
    File.mkdir_p!(carpeta)
    File.write!(Path.join(carpeta, nombre), contenido)
  end

  @doc """
  Lee un archivo completo como texto. Incluso en las pruebas se lee con
  `File.stream!/1` (requisito general 1): en todo el proyecto no se usa `File.read!/1`.
  """
  def leer(ruta), do: ruta |> File.stream!() |> Enum.join()

  @doc "Lee un archivo de salida como lista de líneas."
  def lineas(carpeta, nombre) do
    carpeta |> Path.join(nombre) |> leer() |> String.split("\n", trim: true)
  end
end
