# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :flowmind,
  ecto_repos: [Flowmind.Repo],
  types: Flowmind.PostgresTypes,
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :triplex,
  repo: Flowmind.Repo,
  types: Flowmind.PostgresTypes

# Configures the endpoint
config :flowmind, FlowmindWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FlowmindWeb.ErrorHTML, json: FlowmindWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Flowmind.PubSub,
  live_view: [signing_salt: "JlecbVx4"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :flowmind, Flowmind.Mailer, adapter: Swoosh.Adapters.Local

# config :flowmind, Flowmind.Repo, adapter: Flowmind.PostgrexTypes

config :nx, :default_backend, EXLA.Backend

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  flowmind: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  flowmind: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :daisy_ui_components, translate_function: &FlowmindWeb.CoreComponents.translate_error/1

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
