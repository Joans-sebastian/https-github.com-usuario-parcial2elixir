defmodule Problema2Test do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Mapa.{Regiones, Svg, Validacion}

  defp filas(texto) do
    texto
    |> String.split("\n", trim: true)
    |> Enum.with_index(1)
    |> Enum.map(fn {linea, n} -> {n, String.split(linea)} end)
  end

  defp paleta(lineas) do
    lineas |> Enum.with_index(1) |> Enum.map(fn {t, n} -> {n, Color.parse({n, t})} end)
  end

  @paleta_ok ["A,agua,#2563EB", "B,bosque,#16A34A", "C,cultivo,#F59E0B", ".,fondo,#F1F5F9"]

  describe "validación recursiva" do
    test "datos correctos no reportan problemas" do
      assert Validacion.validar(filas("A A\n. B"), paleta(@paleta_ok)) == []
    end

    test "reporta todos los problemas de mapa y paleta" do
      problemas =
        Validacion.validar(
          filas("A A . B\nA . X B B\n. . C ."),
          paleta([
            "A,agua,#2563EB",
            "B,bosque,#16A34",
            "C,cultivo,#F59E0B",
            "A,arena,#FDE68A",
            "D,desierto"
          ])
        )

      texto = Enum.join(problemas, "\n")
      assert texto =~ "no tiene la forma #RRGGBB"
      assert texto =~ "'A' está repetido"
      assert texto =~ "3 campos"
      assert texto =~ "falta declarar el símbolo '.'"
      assert texto =~ "tiene 5 columnas y se esperaban 4"
      assert texto =~ "columna 2: el símbolo 'X'"
    end

    test "mapa sin filas" do
      assert ["mapa.txt: el mapa no tiene filas" <> _] =
               Validacion.validar([], paleta(@paleta_ok))
    end

    test "formato hexadecimal" do
      assert Validacion.hex_valido?("#2563eb")
      refute Validacion.hex_valido?("#2563E")
      refute Validacion.hex_valido?("#2563EG")
      refute Validacion.hex_valido?("2563EBA")
    end

    test "requisito 7: el módulo de validación no usa Enum ni Stream" do
      codigo = Apoyo.leer("lib/problema2/validacion.ex") <> Apoyo.leer("lib/comun/lista.ex")
      refute codigo =~ "Enum."
      refute codigo =~ "Stream."
    end
  end

  describe "regiones" do
    test "mapa del enunciado" do
      mapa =
        Regiones.construir_mapa(filas("A A . B B\nA . . B .\n. . C . .\nC C C . B\nC . . B B"))

      assert mapa |> Regiones.encontrar() |> Enum.map(&Region.a_csv/1) == [
               "1;A;3;8;{0,0};{1,1}",
               "2;B;3;8;{0,3};{1,4}",
               "3;C;5;12;{2,0};{4,2}",
               "4;B;3;8;{3,3};{4,4}"
             ]
    end

    test "las diagonales no unen regiones" do
      mapa = Regiones.construir_mapa(filas("A .\n. A"))
      assert length(Regiones.encontrar(mapa)) == 2
    end

    test "solo fondo: ninguna región" do
      assert Regiones.encontrar(Regiones.construir_mapa(filas(". .\n. ."))) == []
    end

    test "una región grande no repite casillas" do
      mapa =
        Regiones.construir_mapa(filas(String.duplicate(String.duplicate("A ", 30) <> "\n", 30)))

      assert [%Region{area: 900, perimetro: 120}] = Regiones.encontrar(mapa)
    end
  end

  test "escape XML" do
    assert Svg.escapar_xml(~s(agua & "río" <dulce>)) == "agua &amp; &quot;río&quot; &lt;dulce&gt;"
  end

  describe "programa completo" do
    test "caso del enunciado: CSV exacto y SVG bien formado" do
      salida = Apoyo.carpeta_temporal("p2_ejemplo")
      capture_io(fn -> assert {:ok, _} = Problema2.main("datos/problema2/ejemplo", salida) end)

      assert Apoyo.lineas(salida, "regiones.csv") == [
               "id;simbolo;area;perimetro;desde;hasta",
               "1;A;3;8;{0,0};{1,1}",
               "2;B;3;8;{0,3};{1,4}",
               "3;C;5;12;{2,0};{4,2}",
               "4;B;3;8;{3,3};{4,4}"
             ]

      svg = Apoyo.leer(Path.join(salida, "mapa_regiones.svg"))
      assert svg =~ ~s(width="200" height="200")
      # 25 casillas + 1 rectángulo de fondo
      assert length(Regex.scan(~r/<rect /, svg)) == 26
      assert length(Regex.scan(~r/<text /, svg)) == 4
      # Se puede leer como XML válido
      assert {_, _} = svg |> :binary.bin_to_list() |> :xmerl_scan.string(quiet: true)
    end

    test "caso inválido: no genera regiones ni SVG" do
      salida = Apoyo.carpeta_temporal("p2_invalido")

      capture_io(:stderr, fn ->
        capture_io(fn ->
          assert {:error, [_ | _]} = Problema2.main("datos/problema2/invalido", salida)
        end)
      end)

      assert File.exists?(Path.join(salida, "validacion_mapa.txt"))
      refute File.exists?(Path.join(salida, "regiones.csv"))
      refute File.exists?(Path.join(salida, "mapa_regiones.svg"))
    end

    test "empates y caracteres especiales en la paleta" do
      salida = Apoyo.carpeta_temporal("p2_empates")

      capture_io(fn ->
        assert {:ok, regiones} = Problema2.main("datos/problema2/empates", salida)
        assert length(regiones) == 5
      end)

      [_numero, area, _perimetro] = Apoyo.lineas(salida, "resumen_regiones.txt")
      assert area =~ "región 1" and area =~ "región 5"
      svg = Apoyo.leer(Path.join(salida, "mapa_regiones.svg"))
      assert svg =~ "agua &amp; &quot;rio&quot; &lt;dulce&gt;"
      assert {_, _} = svg |> :binary.bin_to_list() |> :xmerl_scan.string(quiet: true)
    end

    test "archivo faltante: informa cuál falta" do
      error =
        capture_io(:stderr, fn ->
          capture_io(fn ->
            assert {:error, {:faltan_archivos, _}} =
                     Problema2.main("datos/problema2/faltante", Apoyo.carpeta_temporal("p2_f"))
          end)
        end)

      assert error =~ "paleta.csv"
    end
  end
end
