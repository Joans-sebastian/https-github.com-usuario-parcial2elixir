defmodule Problema1 do
  @moduledoc """
  **Problema 1: rutas de entrega en una red dirigida.** Programa principal.

  Flujo completo (descomposición del problema):

  1. Verificar que existan `tramos.csv` y `consultas.txt`.
  2. Leer `tramos.csv` de forma perezosa y convertir cada línea con
     `Tramo.parse/1` → errores a `errores_tramos.txt`.
  3. Depurar recursivamente (`Rutas.Depuracion`) → `depuracion_tramos.txt`.
  4. Construir el grafo (`Rutas.Busqueda.construir_grafo/1`).
  5. Para cada consulta (leída también como Stream, una a la vez):
     - si un centro no existe, se informa y no se busca;
     - Stream infinito de alcance (`Rutas.Alcance`) → `alcance_centros.txt`;
     - si el destino no es alcanzable: «sin itinerarios», sin búsqueda;
     - si lo es: búsqueda recursiva y óptimos → `itinerarios.txt`.
  6. En pantalla, el total de itinerarios por consulta.

  ## Uso

      mix run problema1.exs datos/problema1/ejemplo

  o desde `iex -S mix`:

      Problema1.main("datos/problema1/ejemplo", "salidas/problema1/ejemplo")
  """

  alias Rutas.{Alcance, Busqueda, Depuracion}

  @entrada_por_defecto "datos/problema1/ejemplo"

  @doc """
  Ejecuta el problema 1 con los archivos de `dir_entrada` y deja los resultados
  en `dir_salida` (por defecto `salidas/problema1/<nombre del caso>`).

  Retorna `{:ok, totales}` con `[{"A,D", 4}, ...]` o `{:error, motivo}`.
  Nunca termina con una excepción por un archivo faltante.
  """
  def main(dir_entrada \\ @entrada_por_defecto, dir_salida \\ nil) do
    dir_salida = dir_salida || Path.join("salidas/problema1", Path.basename(dir_entrada))
    ruta_tramos = Path.join(dir_entrada, "tramos.csv")
    ruta_consultas = Path.join(dir_entrada, "consultas.txt")

    Util2.mostrar("\n=== Problema 1: rutas de entrega (#{dir_entrada}) ===", :mensaje)

    case Entrada.verificar_archivos([ruta_tramos, ruta_consultas]) do
      :ok ->
        ejecutar(ruta_tramos, ruta_consultas, dir_salida)

      {:error, faltantes} ->
        Enum.each(faltantes, &Util2.mostrar("Falta el archivo requerido: #{&1}", :error))
        {:error, {:faltan_archivos, faltantes}}
    end
  end

  # ---------------------------------------------------------------------------
  # Etapas
  # ---------------------------------------------------------------------------

  defp ejecutar(ruta_tramos, ruta_consultas, dir_salida) do
    # 2. Lectura perezosa + parse. El grafo se arma DESPUÉS de consumir el Stream.
    {validos, errores} = leer_tramos(ruta_tramos)
    Salida.escribir(Path.join(dir_salida, "errores_tramos.txt"), lineas_errores(errores))

    # 3. Validación previa recursiva.
    {conservados, descartes} = Depuracion.depurar(validos)
    Salida.escribir(Path.join(dir_salida, "depuracion_tramos.txt"), lineas_depuracion(descartes))

    # 4. Grafo.
    grafo = Busqueda.construir_grafo(conservados)
    centros = Busqueda.centros(conservados)

    Util2.mostrar(
      "Tramos válidos: #{length(validos)} | con error: #{length(errores)} | " <>
        "descartados al depurar: #{length(descartes)} | en la red: #{length(conservados)}",
      :mensaje
    )

    # 5 y 6. Consultas.
    totales = procesar_consultas(ruta_consultas, grafo, centros, dir_salida)
    Util2.mostrar("Archivos generados en #{dir_salida}", :mensaje)
    {:ok, totales}
  end

  # Consume el Stream de líneas UNA vez, separando tramos válidos y errores.
  # Los acumuladores se llenan al revés y se invierten al final.
  defp leer_tramos(ruta) do
    {validos, errores} =
      ruta
      |> Entrada.lineas_utiles()
      |> Stream.map(fn {numero, texto} -> {numero, texto, Tramo.parse({numero, texto})} end)
      |> Enum.reduce({[], []}, fn
        {_numero, _texto, {:ok, tramo}}, {validos, errores} ->
          {[tramo | validos], errores}

        {numero, texto, {:error, motivo}}, {validos, errores} ->
          {validos, [{numero, texto, motivo} | errores]}
      end)

    {Enum.reverse(validos), Enum.reverse(errores)}
  end

  # Las consultas se leen como Stream y se resuelven una por una: cada bloque se
  # escribe en los dos archivos de salida en cuanto la consulta se resuelve.
  defp procesar_consultas(ruta_consultas, grafo, centros, dir_salida) do
    Salida.con_archivo(Path.join(dir_salida, "itinerarios.txt"), fn itinerarios ->
      Salida.con_archivo(Path.join(dir_salida, "alcance_centros.txt"), fn alcance ->
        ruta_consultas
        |> Entrada.lineas_utiles()
        |> Stream.map(&parse_consulta/1)
        |> Enum.map(&resolver(&1, grafo, centros, itinerarios, alcance))
      end)
    end)
  end

  defp parse_consulta({numero, texto}) do
    case texto |> String.split(",") |> Enum.map(&String.trim/1) do
      [origen, destino] when origen != "" and destino != "" ->
        {:ok, origen, destino}

      _ ->
        {:error, numero, texto, "se esperaba el formato origen,destino"}
    end
  end

  # ---------------------------------------------------------------------------
  # Resolución de una consulta (pattern matching sobre el resultado del parse)
  # ---------------------------------------------------------------------------

  defp resolver({:error, numero, texto, motivo}, _grafo, _centros, itinerarios, alcance) do
    titulo = "=== Consulta inválida (línea #{numero}): #{texto} ==="
    escribir_bloque(itinerarios, [titulo, "Motivo: #{motivo}"])
    escribir_bloque(alcance, [titulo, "Motivo: #{motivo}"])
    Util2.mostrar("Línea #{numero}: consulta inválida '#{texto}' (#{motivo})", :error)
    {texto, :invalida}
  end

  defp resolver({:ok, origen, destino}, grafo, centros, itinerarios, alcance) do
    titulo = "=== #{origen} → #{destino} ==="
    consulta = "#{origen},#{destino}"

    case centros_inexistentes([origen, destino], centros) do
      [] ->
        resolver_existente(origen, destino, grafo, titulo, itinerarios, alcance, consulta)

      faltantes ->
        mensaje = mensaje_inexistentes(faltantes)
        escribir_bloque(itinerarios, [titulo, mensaje])
        escribir_bloque(alcance, [titulo, mensaje])
        Util2.mostrar("#{origen} → #{destino}: #{mensaje}", :error)
        {consulta, :centro_inexistente}
    end
  end

  defp resolver_existente(origen, destino, grafo, titulo, itinerarios, alcance, consulta) do
    # Stream infinito: se consumen solo los pasos necesarios.
    {estados, paso_estable} = Alcance.hasta_estabilizar(grafo, origen)
    alcanzable = MapSet.member?(List.last(estados), destino)
    escribir_bloque(alcance, lineas_alcance(titulo, estados, paso_estable, destino, alcanzable))

    if alcanzable do
      encontrados = Busqueda.itinerarios(grafo, origen, destino)
      escribir_bloque(itinerarios, lineas_itinerarios(titulo, encontrados))
      Util2.mostrar("#{origen} → #{destino}: #{total(length(encontrados))}", :mensaje)
      {consulta, length(encontrados)}
    else
      escribir_bloque(itinerarios, [
        titulo,
        "El destino #{destino} no es alcanzable desde #{origen}: sin itinerarios " <>
          "(se omitió la búsqueda exhaustiva).",
        "Total: 0 itinerarios"
      ])

      Util2.mostrar("#{origen} → #{destino}: sin itinerarios", :mensaje)
      {consulta, 0}
    end
  end

  defp centros_inexistentes(consultados, centros) do
    consultados
    |> Enum.uniq()
    |> Util2.aplicar_filtro(&(not MapSet.member?(centros, &1)))
  end

  defp mensaje_inexistentes([centro]),
    do: "el centro #{centro} no existe en la red; no se inicia la búsqueda"

  defp mensaje_inexistentes(centros),
    do: "los centros #{Enum.join(centros, " y ")} no existen en la red; no se inicia la búsqueda"

  # ---------------------------------------------------------------------------
  # Formato de los reportes (funciones puras: datos → líneas de texto)
  # ---------------------------------------------------------------------------

  defp lineas_errores([]), do: ["Sin errores: todas las líneas de tramos.csv son correctas."]

  defp lineas_errores(errores) do
    ["Líneas de tramos.csv con formato o datos incorrectos: #{length(errores)}"] ++
      Util2.convertir_coleccion_mensaje(errores, fn {numero, texto, motivo} ->
        "Línea #{numero}: #{texto} | motivo: #{motivo}"
      end)
  end

  defp lineas_depuracion([]), do: ["Sin descartes: la red no tiene bucles ni tramos repetidos."]

  defp lineas_depuracion(descartes) do
    ["Tramos descartados en la depuración: #{length(descartes)}"] ++
      Util2.convertir_coleccion_mensaje(descartes, fn {tramo, motivo} ->
        "Línea #{tramo.linea}: #{tramo.contenido} | motivo: #{motivo}"
      end)
  end

  defp lineas_alcance(titulo, estados, paso_estable, destino, alcanzable) do
    pasos =
      estados
      |> Enum.with_index()
      |> Enum.map(fn {conjunto, paso} -> "Paso #{paso}: #{Alcance.formatear(conjunto)}" end)

    [titulo] ++
      pasos ++
      [
        "Paso #{paso_estable + 1}: repite el paso #{paso_estable} → se estabiliza en el paso #{paso_estable}",
        "Elementos del Stream consumidos: #{paso_estable + 2} (pasos 0 a #{paso_estable + 1})",
        if(alcanzable,
          do: "Destino #{destino}: alcanzable",
          else: "Destino #{destino}: no alcanzable → sin itinerarios"
        )
      ]
  end

  defp lineas_itinerarios(titulo, encontrados) do
    optimos = Busqueda.optimos(encontrados)

    detalle =
      encontrados
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {itinerario, numero} ->
        [
          "Itinerario #{numero}: #{itinerario}",
          "    tramos usados: #{Itinerario.detalle_tramos(itinerario)}"
        ]
      end)

    [titulo] ++
      detalle ++
      [
        "Total: #{total(length(encontrados))}",
        "Menos tramos: #{Enum.join(optimos.tramos, ", ")}",
        "Menor tiempo: #{Enum.join(optimos.minutos, ", ")}",
        "Menor costo: #{Enum.join(optimos.costo, ", ")}"
      ]
  end

  defp total(1), do: "1 itinerario"
  defp total(n), do: "#{n} itinerarios"

  # Escribe las líneas de un bloque y una línea en blanco de separación.
  defp escribir_bloque(dispositivo, lineas) do
    Enum.each(lineas, &Salida.linea(dispositivo, &1))
    Salida.linea(dispositivo, "")
  end
end
