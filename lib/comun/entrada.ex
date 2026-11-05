defmodule Entrada do
  @moduledoc """
  Lectura **perezosa** de los archivos de entrada. La usan los dos problemas.

  Cumple los requisitos generales 1, 2, 3 y 6 del parcial:

  - Lee cada archivo con `File.stream!/1`, línea por línea (nunca `File.read!/1`).
  - Limpia y filtra las líneas con transformaciones perezosas (`Stream`), sin
    crear listas intermedias.
  - Ignora las líneas en blanco y las que empiezan por `#` (comentarios).
  - Conserva el número de **línea física** original para reportar errores.
  - Verifica antes de leer que los archivos requeridos existan.
  """

  @doc """
  Verifica que existan todos los archivos requeridos.

  Retorna `:ok` o `{:error, faltantes}` con la lista de rutas que no existen.
  Así el programa informa cuál falta en lugar de terminar con una excepción.

  Reutiliza `Util2.aplicar_filtro/2` (módulo del curso) para quedarse con las
  rutas que no son archivos regulares.

  ## Ejemplo

      Entrada.verificar_archivos(["datos/tramos.csv", "datos/consultas.txt"])
  """
  def verificar_archivos(rutas) do
    case Util2.aplicar_filtro(rutas, &(not File.regular?(&1))) do
      [] -> :ok
      faltantes -> {:error, faltantes}
    end
  end

  @doc """
  Devuelve un **Stream** (perezoso) de tuplas `{numero_linea, texto}` con las
  líneas útiles del archivo.

  Hasta que alguien consuma el Stream no se lee nada del disco. Cada línea:

  1. se numera con su línea física (empezando en 1),
  2. se limpia (quita el salto de línea `\\r\\n`, espacios finales y un posible BOM),
  3. se descarta si está en blanco o es un comentario.

  ## Ejemplo

      "datos/problema1/ejemplo/tramos.csv"
      |> Entrada.lineas_utiles()
      |> Enum.take(2)
      #=> [{2, "A,B,8,5"}, {3, "B,D,7,4"}]
  """
  def lineas_utiles(ruta) do
    ruta
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.map(&limpiar/1)
    |> Stream.reject(fn {_numero, texto} -> ignorable?(texto) end)
  end

  @doc """
  Indica si una línea se debe ignorar: está en blanco o su primer carácter no
  blanco es `#`.

  ## Ejemplos

      Entrada.ignorable?("   ")          #=> true
      Entrada.ignorable?("  # comentario") #=> true
      Entrada.ignorable?("A,B,8,5")      #=> false
  """
  def ignorable?(texto) do
    sin_espacios = String.trim(texto)
    sin_espacios == "" or String.starts_with?(sin_espacios, "#")
  end

  # Quita el BOM (si el archivo se guardó con él) y los espacios/saltos finales.
  defp limpiar({linea, numero}) do
    texto =
      linea
      |> String.trim_leading("﻿")
      |> String.trim_trailing()

    {numero, texto}
  end
end
