defmodule SiwappWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :siwapp

  alias Phoenix.Controller
  alias Plug.Conn

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_siwapp_key",
    signing_salt: "/ANu0gm7"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options], timeout: 45_000]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :siwapp,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  plug PromEx.Plug, prom_ex_module: Siwapp.PromEx

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :siwapp
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Sentry.PlugContext
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug SiwappWeb.Router

  @impl true
  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      e ->
        case e.reason do
          %Ecto.NoResultsError{} ->
            conn =
              e.conn
              |> Conn.put_private(:phoenix_layout, {SiwappWeb.LayoutView, :app})
              |> Conn.put_status(:not_found)
              |> Controller.put_view(SiwappWeb.ErrorView)
              |> Controller.render(:"404")
              |> Conn.halt()

            call(conn, opts)

          _ ->
            raise e
        end
    end
  end
end
