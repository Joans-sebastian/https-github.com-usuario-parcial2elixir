defmodule Util do
  @moduledoc """
  Módulo con funciones que se reutilizan
  - autor: Joan Sebastian Vargas.
  - fecha: Noviembre del 2026
  - licencia: GNU GPL v3
  """

  @doc """
  Función para mostrar un mensaje en la pantalla.

  ## Parámetro

  - mensaje: texto que se le presenta al usuario

  ## Ejemplo

  iex> Util.mostrar_mensaje("Hola Mundo")

  o puede usar

  "Hola Mundo" |> Util.mostrar_mensaje()
  """
  def mostrar_mensaje(mensaje) do
    mensaje
    |> IO.puts()
  end

  @doc """
  Función para mostrar un mensaje de error

  ## Parámetro

  - mensaje: texto que se le presenta al usuario

  ## Ejemplo

  iex> Util.mostrar_error("error ...")

  o puede usar

  "error ..." |> Util.mostrar_error()
  """
  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  @doc """
  Función para ingresar un dato desde teclado

  ## Parámetro

  - mensaje: texto que se le presenta al usuario
  - tipo: identifica el tipo de dato.
         :texto para ingresar una cadena
         :entero para ingresar un valor entero
         :real para ingresar un valor real

  ## Ejemplo

  iex> Util.ingresar("Ingresar nombre: ", :texto)
  iex> Util.ingresar("Ingresar edad: ", :entero)
  iex> Util.ingresar("Ingresar altura: ", :real)

  o puede usar

  "Ingresar nombre: " |> Util.ingresar(:texto)
  "Ingresar edad: "   |> Util.ingresar(:entero)
  "Ingresar altura: " |> Util.ingresar(:real)
  """
  def ingresar(mensaje, :texto) do
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  def ingresar(mensaje, :entero) do
    ingresar(
      mensaje,
      &String.to_integer/1,
      :entero
    )
  end

  def ingresar(mensaje, :real) do
    ingresar(
      mensaje,
      &String.to_float/1,
      :real
    )
  end

  defp ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> Util.ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        "Error, se espera que ingrese un número #{tipo_dato}\n"
        |> mostrar_error()

        mensaje
        |> ingresar(tipo_dato)
    end
  end
end
