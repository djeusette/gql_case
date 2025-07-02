defmodule GqlCase.MixProject do
  use Mix.Project

  def project do
    [
      app: :gql_case,
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "GqlCase",
      source_url: "https://github.com/djeusette/gql_case"
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description,
    do: "GqlCase provides macros to easily test Graphql queries for projects using Absinthe."

  defp package,
    do: [
      name: "gql_case",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/djeusette/gql_case"}
    ]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.18"},
      {:absinthe, "~> 1.7"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
