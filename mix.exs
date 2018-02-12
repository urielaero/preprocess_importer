defmodule PreprocessImporter.Mixfile do
  use Mix.Project

  def project do
    [
      app: :preprocess_importer,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
    {:csv, "~> 2.0.0"},
    {:flow, "~> 0.13"},
    {:jason, "~> 1.0"}]
  end
end
