defmodule Mapa.Svg do
  @moduledoc """
  **Exportación SVG** del mapa de regiones (problema 2).

  El documento se genera **por fragmentos** con `Stream.concat/1`:

  1. encabezado (`<?xml ...>`, `<svg ...>` y el rectángulo de fondo),
  2. un `<rect>` de 40 × 40 px por casilla, con el color de la paleta y borde,
  3. un `<text>` con el ID de cada región, en su primera casilla,
  4. el cierre `</svg>`.

  `Salida.escribir/2` consume ese Stream y escribe cada fragmento en cuanto se
  produce; nunca existe el documento completo en memoria.

  Todo texto que viene de los archivos (nombres de la paleta, símbolos) pasa
  por `escapar_xml/1` antes de entrar al XML.
  """

  @tamano 40

  @doc "Genera el archivo SVG en `ruta`."
  def generar(ruta, mapa, regiones, paleta) do
    ancho = @tamano * mapa.columnas
    alto = @tamano * mapa.filas
    region_de = for region <- regiones, celda <- region.celdas, into: %{}, do: {celda, region}

    # Nada se calcula aquí todavía: el Stream solo describe los fragmentos.
    fragmentos =
      Stream.concat([
        encabezado(ancho, alto, paleta["."].hex),
        Stream.map(Mapa.Regiones.posiciones(mapa), &casilla(&1, mapa.celdas, paleta, region_de)),
        Stream.map(regiones, &etiqueta/1),
        ["</svg>"]
      ])

    # Al escribir se consume el Stream: cada fragmento se genera y se escribe enseguida.
    Salida.escribir(ruta, fragmentos)
  end

  defp encabezado(ancho, alto, color_fondo) do
    [
      ~s(<?xml version="1.0" encoding="UTF-8"?>),
      ~s(<svg xmlns="http://www.w3.org/2000/svg" width="#{ancho}" height="#{alto}" ) <>
        ~s(viewBox="0 0 #{ancho} #{alto}">),
      ~s(<rect x="0" y="0" width="#{ancho}" height="#{alto}" fill="#{color_fondo}"/>)
    ]
  end

  # Un rectángulo por casilla. El <title> aparece al pasar el mouse en el navegador.
  defp casilla({fila, columna} = posicion, celdas, paleta, region_de) do
    simbolo = celdas[posicion]
    color = paleta[simbolo]

    descripcion =
      case region_de[posicion] do
        nil ->
          "Fila #{fila}, columna #{columna}: #{color.nombre} (#{simbolo})"

        region ->
          "Fila #{fila}, columna #{columna}: #{color.nombre} (#{simbolo}), región #{region.id}"
      end

    ~s(<rect x="#{columna * @tamano}" y="#{fila * @tamano}" width="#{@tamano}" ) <>
      ~s(height="#{@tamano}" fill="#{color.hex}" stroke="#334155" stroke-width="1">) <>
      "<title>#{escapar_xml(descripcion)}</title></rect>"
  end

  # El ID se escribe en la primera casilla de la región (la primera en orden de filas).
  defp etiqueta(%Region{id: id, celdas: [{fila, columna} | _]}) do
    x = columna * @tamano + div(@tamano, 2)
    y = fila * @tamano + div(@tamano, 2)

    ~s(<text x="#{x}" y="#{y}" text-anchor="middle" dominant-baseline="central" ) <>
      ~s(font-family="Arial, sans-serif" font-size="18" font-weight="bold" ) <>
      ~s(fill="#0F172A" stroke="#FFFFFF" stroke-width="3" paint-order="stroke">) <>
      "#{escapar_xml(Integer.to_string(id))}</text>"
  end

  @doc """
  Escapa los caracteres especiales de XML. `&` va primero para no escapar dos
  veces los `&` que se agregan.

  ## Ejemplo

      Mapa.Svg.escapar_xml("agua & <río>") #=> "agua &amp; &lt;río&gt;"
  """
  def escapar_xml(texto) do
    texto
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
