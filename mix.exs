defmodule Parcial2.MixProject do
  use Mix.Project

  # Proyecto del Parcial 2 de Programación III (Universidad del Quindío).
  # Problemas resueltos: 1 (rutas de entrega) y 2 (regiones de un mapa + SVG).
  # No usa dependencias externas: solo Elixir estándar.
  def project do
    [
      app: :parcial2,
      version: "1.0.0",
      elixir: "~> 1.15",
      start_permanent: false,
      deps: []
    ]
  end

  def application do
    # :xmerl (incluido en Erlang/OTP) se usa en las pruebas para verificar que el SVG es XML válido.
    [extra_applications: [:logger, :xmerl]]
  end
end
