defmodule Smex.Mixfile do
  use Mix.Project

  def project do
    [app: :smex,
     version: "0.0.1",
     elixir: "~> 1.0",
     description: description,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: {Smex, []},
      applications: [:logger, :amqp]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:amqp, "~> 0.1"},
      {:murmur, "~> 0.2"},
      {:exprotobuf, github: "DylanGriffith/exprotobuf", branch: "dgvz"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
    ]
  end

  # Hex stuff
  defp description do
    """
    An Elixir library for simplifying the sending of protocol buffers over rabbitmq.
    """
  end

  defp package do
    [# These are the default files included in the package
     files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.txt",],
     maintainers: ["Dylan Griffith"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/DylanGriffith/smex"}]
  end
end
