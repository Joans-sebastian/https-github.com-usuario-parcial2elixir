defmodule Problema1Test do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Rutas.{Alcance, Busqueda, Depuracion}

  # Red del enunciado ya depurada (sin A,A ni el segundo A,B).
  defp red_ejemplo do
    [
      {2, "A,B,8,5"},
      {3, "B,D,7,4"},
      {4, "A,C,6,2"},
      {5, "C,D,12,1"},
      {6, "B,C,3,2"},
      {7, "C,B,4,1"}
    ]
    |> Enum.map(fn linea -> linea |> Tramo.parse() |> elem(1) end)
  end

  describe "Tramo.parse/1" do
    test "convierte una línea válida" do
      assert {:ok, %Tramo{origen: "A", destino: "B", minutos: 8, costo: 5}} =
               Tramo.parse("A,B,8,5")
    end

    test "conserva la línea física y tolera espacios" do
      assert {:ok, %Tramo{origen: "A", destino: "B", linea: 7}} =
               Tramo.parse({7, " A , B , 8 , 5 "})
    end

    test "rechaza cantidad de campos incorrecta" do
      assert {:error, motivo} = Tramo.parse("C,D,5")
      assert motivo =~ "4 campos"
    end

    test "rechaza valores no numéricos, cero, negativos y centros vacíos" do
      assert {:error, _} = Tramo.parse("B,C,ocho,4")
      assert {:error, _} = Tramo.parse("B,C,8.5,4")
      assert {:error, _} = Tramo.parse("D,E,0,3")
      assert {:error, _} = Tramo.parse("E,F,4,-2")
      assert {:error, _} = Tramo.parse(",F,3,3")
    end
  end

  describe "depuración recursiva" do
    test "descarta bucles y repetidos, conserva la primera aparición y los sentidos contrarios" do
      tramos =
        [{2, "A,B,8,5"}, {8, "A,A,2,1"}, {9, "A,B,9,7"}, {10, "B,A,1,1"}]
        |> Enum.map(&(&1 |> Tramo.parse() |> elem(1)))

      {conservados, descartes} = Depuracion.depurar(tramos)

      assert Enum.map(conservados, & &1.linea) == [2, 10]
      assert [{%Tramo{linea: 8}, bucle}, {%Tramo{linea: 9}, repetido}] = descartes
      assert bucle =~ "bucle"
      assert repetido =~ "línea 2"
    end

    test "el descarte conserva la línea física y el contenido original, con sus espacios" do
      tramos =
        Enum.map([{2, "A,B,8,5"}, {6, " A , B , 9 , 7 "}], &(&1 |> Tramo.parse() |> elem(1)))

      assert {_, [{%Tramo{linea: 6, contenido: " A , B , 9 , 7 "}, _motivo}]} =
               Depuracion.depurar(tramos)
    end

    test "lista vacía" do
      assert Depuracion.depurar([]) == {[], []}
    end

    test "requisito 7: el módulo de validación no usa Enum ni Stream" do
      codigo = Apoyo.leer("lib/problema1/depuracion.ex")
      refute codigo =~ "Enum."
      refute codigo =~ "Stream."
    end
  end

  describe "búsqueda de itinerarios" do
    test "encuentra los 4 itinerarios del enunciado, en el mismo orden" do
      grafo = Busqueda.construir_grafo(red_ejemplo())
      itinerarios = Busqueda.itinerarios(grafo, "A", "D")

      assert Enum.map(itinerarios, &to_string/1) == [
               "A → B → D | tramos: 2 | 15 min | costo: 9",
               "A → B → C → D | tramos: 3 | 23 min | costo: 8",
               "A → C → D | tramos: 2 | 18 min | costo: 3",
               "A → C → B → D | tramos: 3 | 17 min | costo: 7"
             ]

      assert Busqueda.optimos(itinerarios) == %{tramos: [1, 3], minutos: [1], costo: [3]}
    end

    test "origen igual a destino da un itinerario de 0 tramos" do
      grafo = Busqueda.construir_grafo(red_ejemplo())

      assert [%Itinerario{centros: ["A"], minutos: 0, costo: 0}] =
               Busqueda.itinerarios(grafo, "A", "A")
    end

    test "conserva empates en los tres criterios" do
      tramos =
        Enum.map(["A,B,1,1", "B,D,1,1", "A,C,1,1", "C,D,1,1"], &(&1 |> Tramo.parse() |> elem(1)))

      itinerarios = tramos |> Busqueda.construir_grafo() |> Busqueda.itinerarios("A", "D")
      assert Busqueda.optimos(itinerarios) == %{tramos: [1, 2], minutos: [1, 2], costo: [1, 2]}
    end
  end

  describe "Stream infinito de alcance" do
    test "se estabiliza en el paso 2 para A" do
      grafo = Busqueda.construir_grafo(red_ejemplo())
      {estados, paso} = Alcance.hasta_estabilizar(grafo, "A")

      assert paso == 2
      assert Enum.map(estados, &Alcance.formatear/1) == ["{A}", "{A, B, C}", "{A, B, C, D}"]
    end

    test "A no es alcanzable desde B" do
      grafo = Busqueda.construir_grafo(red_ejemplo())
      {estados, _paso} = Alcance.hasta_estabilizar(grafo, "B")
      refute MapSet.member?(List.last(estados), "A")
    end

    test "el Stream es infinito: se pueden pedir tantos pasos como se quiera" do
      grafo = Busqueda.construir_grafo(red_ejemplo())
      assert grafo |> Alcance.secuencia("A") |> Enum.take(50) |> length() == 50
    end
  end

  describe "programa completo" do
    test "caso del enunciado" do
      salida = Apoyo.carpeta_temporal("p1_ejemplo")

      capture_io(fn ->
        assert {:ok, [{"A,D", 4}, {"B,A", 0}]} = Problema1.main("datos/problema1/ejemplo", salida)
      end)

      itinerarios = Apoyo.lineas(salida, "itinerarios.txt")
      assert "Itinerario 1: A → B → D | tramos: 2 | 15 min | costo: 9" in itinerarios
      assert "Menos tramos: 1, 3" in itinerarios
      assert "Menor tiempo: 1" in itinerarios
      assert "Menor costo: 3" in itinerarios

      depuracion = Apoyo.lineas(salida, "depuracion_tramos.txt")
      assert Enum.any?(depuracion, &String.starts_with?(&1, "Línea 8: A,A,2,1"))
      assert Enum.any?(depuracion, &String.starts_with?(&1, "Línea 9: A,B,9,7"))
    end

    test "caso inválido: reporta errores con su línea física" do
      salida = Apoyo.carpeta_temporal("p1_invalido")

      capture_io(:stderr, fn ->
        capture_io(fn -> Problema1.main("datos/problema1/invalido", salida) end)
      end)

      errores = Apoyo.lineas(salida, "errores_tramos.txt")
      assert Enum.any?(errores, &String.starts_with?(&1, "Línea 3: B,C,ocho,4"))
      assert Enum.any?(errores, &String.starts_with?(&1, "Línea 7: ,F,3,3"))

      itinerarios = Apoyo.leer(Path.join(salida, "itinerarios.txt"))
      assert itinerarios =~ "el centro Z no existe"
      assert itinerarios =~ "Consulta inválida (línea 5)"
    end

    test "archivo faltante: informa cuál falta y no lanza excepción" do
      salida = Apoyo.carpeta_temporal("p1_faltante")

      error =
        capture_io(:stderr, fn ->
          capture_io(fn ->
            assert {:error, {:faltan_archivos, [faltante]}} =
                     Problema1.main("datos/problema1/faltante", salida)

            assert faltante =~ "consultas.txt"
          end)
        end)

      assert error =~ "Falta el archivo requerido"
    end
  end
end
