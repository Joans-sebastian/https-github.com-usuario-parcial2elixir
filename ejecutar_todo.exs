# Ejecuta todos los casos de prueba de los dos problemas.
# Cada caso deja sus resultados en salidas/problemaN/<caso>/.
#
#   mix run ejecutar_todo.exs

for problema <- ["problema1", "problema2"] do
  casos =
    Path.join("datos", problema)
    |> File.ls!()
    |> Enum.sort()

  for caso <- casos do
    entrada = Path.join(["datos", problema, caso])

    case problema do
      "problema1" -> Problema1.main(entrada)
      "problema2" -> Problema2.main(entrada)
    end
  end
end
