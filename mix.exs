defmodule Flowmind.MixProject do
  use Mix.Project

  def project do
    [
      app: :flowmind,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Flowmind.Application, []},
      extra_applications: [:logger, :runtime_tools, :mnesia]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    # export WHATSAPPX_PATH=/Users/beltre.wilton/apps/whatsappx
    whatsappx_path = System.get_env("WHATSAPPX_PATH")
    # country_lookup = System.get_env("COUNTRY_LOOKUP")

    [
      {:argon2_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.18"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      # {:floki, ">= 0.30.0", only: :test},
      {:floki, ">= 0.30.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:plug_cowboy, "~> 2.7.2"},
      {:triplex, "~> 1.3.0"},
      {:corsica, "~> 2.1"},
      {:langchain, "~> 0.3.2"},
      {:pgvector, "~> 0.3.0"},
      {:bumblebee, "~> 0.6.0"},
      {:exla, "~> 0.9.2"},
      {:oauth2, "~> 2.1"},
      {:text_chunker, "~> 0.3.2"},
      {:daisy_ui_components, "~> 0.8"},
      {:whatsappx, path: whatsappx_path},
      {:country_lookup, "~> 0.0.2"},
      {:google_api_gmail, "~> 0.17.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind flowmind", "esbuild flowmind"],
      "assets.deploy": [
        "tailwind flowmind --minify",
        "esbuild flowmind --minify",
        "phx.digest"
      ]
    ]
  end
end
