defmodule Salida do
  @moduledoc """
  Escritura **por flujo** de los archivos de salida (requisito general 4).

  Nunca se arma un único string con todo el resultado: cada línea o fragmento
  se escribe en el archivo a medida que se produce. Cada ejecución crea o
  reemplaza el archivo (modo `:write`).

  Hay dos formas de escribir:

  - `escribir/2`: recibe cualquier enumerable de líneas (lista o `Stream`) y lo
    vuelca al archivo con `Stream.into/2`. Se usa para archivos que se generan
    de una sola vez (CSV, SVG, reportes).
  - `con_archivo/2` + `linea/2`: abre el archivo y entrega el dispositivo para
    escribir línea por línea mientras se procesa algo (por ejemplo, cada
    consulta del problema 1 en cuanto se resuelve).
  """

  @doc """
  Escribe en `ruta` cada elemento de `lineas` seguido de un salto de línea.

  `lineas` puede ser una lista o un `Stream`; si es un Stream, cada línea se
  calcula justo antes de escribirse.

  ## Ejemplo

      Salida.escribir("salidas/demo.txt", ["línea 1", "línea 2"])
  """
  def escribir(ruta, lineas) do
    preparar_carpeta(ruta)

    lineas
    |> Stream.map(&[&1, "\n"])
    |> Stream.into(File.stream!(ruta))
    |> Stream.run()

    ruta
  end

  @doc """
  Abre `ruta` para escritura (UTF-8), ejecuta `funcion.(dispositivo)` y cierra
  el archivo al terminar. Retorna lo que retorne `funcion`.

  ## Ejemplo

      Salida.con_archivo("salidas/demo.txt", fn archivo ->
        Salida.linea(archivo, "Hola")
      end)
  """
  def con_archivo(ruta, funcion) do
    preparar_carpeta(ruta)

    case File.open(ruta, [:write, :utf8], funcion) do
      {:ok, resultado} ->
        resultado

      {:error, razon} ->
        Util2.mostrar("No se pudo escribir #{ruta}: #{inspect(razon)}", :error)
        {:error, razon}
    end
  end

  @doc "Escribe una línea (con salto de línea) en un archivo abierto con `con_archivo/2`."
  def linea(dispositivo, texto), do: IO.write(dispositivo, [texto, "\n"])

  @doc """
  Elimina archivos de salida de una ejecución anterior. Se usa cuando la
  validación falla, para que no queden resultados viejos que confundan.
  """
  def eliminar(rutas), do: Enum.each(rutas, &File.rm/1)

  defp preparar_carpeta(ruta), do: File.mkdir_p!(Path.dirname(ruta))
end
