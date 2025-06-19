defmodule Flowmind.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FlowmindWeb.Telemetry,
      Flowmind.Repo,
      {DNSCluster, query: Application.get_env(:flowmind, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Flowmind.PubSub},
      FlowmindWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: Flowmind.Finch},
      # Start a worker by calling: Flowmind.Worker.start_link(arg)
      # {Flowmind.Worker, arg},
      # Start to serve requests, typically the last entry
      FlowmindWeb.Endpoint,
      {Plug.Cowboy, scheme: :http, plug: Webhook.Router, options: [port: 7001]},
      Flowmind.TenantGenServer,
      # Flowmind.EmbeddingGenserver,
      {Task, fn -> Flowmind.Data.Mem.start() end},
      CountryLookup
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Flowmind.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FlowmindWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
