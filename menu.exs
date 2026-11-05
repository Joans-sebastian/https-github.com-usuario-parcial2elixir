defmodule Menu do
  @moduledoc """
  Menú interactivo para la sustentación. Reutiliza los módulos del curso:

  - `Util.mostrar_mensaje/1` (versión 1) para el encabezado,
  - `Util2.ingresar/2` (versión 2) para leer y validar la opción y el caso.

      mix run menu.exs
  """

  def main do
    Util.mostrar_mensaje("""

    ==============================================
     Parcial 2 - Programación III - Elixir
     1. Rutas de entrega en una red dirigida
     2. Regiones de un mapa de colores + SVG
     0. Salir
    ==============================================
    """)

    case Util2.ingresar("Elija una opción: ", :entero) do
      0 ->
        Util2.mostrar("Hasta luego.", :mensaje)

      opcion when opcion in [1, 2] ->
        ejecutar(opcion)
        main()

      _ ->
        Util2.mostrar("Opción no válida.", :error)
        main()
    end
  end

  defp ejecutar(opcion) do
    carpeta = "datos/problema#{opcion}"
    casos = carpeta |> File.ls!() |> Enum.sort()

    casos
    |> Util2.convertir_coleccion_mensaje()
    |> then(&Util.mostrar_mensaje(["Casos disponibles:\n" | &1]))

    caso = Util2.ingresar("Nombre del caso: ", :texto)
    entrada = Path.join(carpeta, caso)

    case opcion do
      1 -> Problema1.main(entrada)
      2 -> Problema2.main(entrada)
    end
  end
end

Menu.main()
