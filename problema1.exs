# Ejecuta el problema 1 (rutas de entrega).
#
#   mix run problema1.exs                           -> caso datos/problema1/ejemplo
#   mix run problema1.exs datos/problema1/invalido  -> otro caso
#   mix run problema1.exs <entrada> <salida>        -> carpeta de salida propia

case System.argv() do
  [] -> Problema1.main()
  [entrada] -> Problema1.main(entrada)
  [entrada, salida | _] -> Problema1.main(entrada, salida)
end
