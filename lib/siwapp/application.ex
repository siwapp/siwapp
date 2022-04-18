defmodule Siwapp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)

    children = [
      # Start the Ecto repository
      Siwapp.Repo,
      # Start the Telemetry supervisor
      SiwappWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Siwapp.PubSub},
      # Start the Endpoint (http/https)
      SiwappWeb.Endpoint,
      ChromicPDF,
      # Start a worker by calling: Siwapp.Worker.start_link(arg)
      # {Siwapp.Worker, arg}
      {Cachex, name: :siwapp_cache},
      Siwapp.TimerEvents
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Siwapp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    SiwappWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
