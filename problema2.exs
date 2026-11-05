# Ejecuta el problema 2 (regiones de un mapa + SVG).
#
#   mix run problema2.exs                           -> caso datos/problema2/ejemplo
#   mix run problema2.exs datos/problema2/invalido  -> otro caso
#   mix run problema2.exs <entrada> <salida>        -> carpeta de salida propia

case System.argv() do
  [] -> Problema2.main()
  [entrada] -> Problema2.main(entrada)
  [entrada, salida | _] -> Problema2.main(entrada, salida)
end
