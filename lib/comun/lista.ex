defmodule Lista do
  @moduledoc """
  Funciones **recursivas propias** sobre listas.

  El requisito general 7 prohíbe usar los módulos de colecciones y flujos de
  la biblioteca estándar dentro de las validaciones previas. Por eso las
  validaciones de ambos problemas usan estas funciones, escritas con
  recursión de cola y un acumulador.
  """

  @doc """
  Invierte una lista.

  Las validaciones acumulan resultados con `[nuevo | acumulador]` (agregar al
  inicio es O(1)), lo que los deja al revés; al final se invierten una vez.

  ## Ejemplo

      Lista.invertir([1, 2, 3]) #=> [3, 2, 1]
  """
  def invertir(lista), do: invertir(lista, [])

  defp invertir([], acumulador), do: acumulador
  defp invertir([cabeza | cola], acumulador), do: invertir(cola, [cabeza | acumulador])

  @doc """
  Cuenta los elementos de una lista.

  ## Ejemplo

      Lista.contar(["A", "B", "."]) #=> 3
  """
  def contar(lista), do: contar(lista, 0)

  defp contar([], total), do: total
  defp contar([_cabeza | cola], total), do: contar(cola, total + 1)
end
