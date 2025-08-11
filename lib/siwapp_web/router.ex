defmodule SiwappWeb.Router do
  use SiwappWeb, :router

  import SiwappWeb.UserAuth

  @env Application.compile_env!(:siwapp, :env)

  @secure_headers %{
    "x-frame-options" => "SAMEORIGIN",
    "x-xss-protection" => "1; mode=block",
    "x-content-type-options" => "nosniff",
    "content-security-policy" =>
      "default-src 'self'; script-src 'self' https://kit.fontawesome.com; style-src 'self' 'unsafe-inline' data: https://ka-f.fontawesome.com; font-src 'self' data: https://ka-f.fontawesome.com; connect-src 'self' https://ka-f.fontawesome.com; img-src 'self' data:"
  }

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SiwappWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, @secure_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  end

  pipeline :token_authenticated do
    plug SiwappWeb.Plugs.Authenticate
  end

  scope "/api", SiwappWeb do
    pipe_through :api

    post "/sign_in", Api.TokenController, :create
  end

  scope "/graphql" do
    if @env in [:dev, :test] do
      pipe_through :api
      forward "/graphiql", Absinthe.Plug.GraphiQL, schema: SiwappWeb.Schema
    else
      pipe_through [:api, :token_authenticated]
    end

    forward "/", Absinthe.Plug, schema: SiwappWeb.Schema
  end

  # Other scopes may use custom stacks.
  scope "/api", SiwappWeb do
    pipe_through [:api, :token_authenticated]

    get "/invoices/download/:id", Api.InvoicesController, :download
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if @env in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SiwappWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if @env == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SiwappWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", SiwappWeb do
    pipe_through(:browser)

    get("/status", StatusController, :status)
  end

  scope "/", SiwappWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :user, on_mount: SiwappWeb.UserAuthLive do
      live "/", HomeLive.Index, :index

      get "/users/settings", UserSettingsController, :edit
      put "/users/settings", UserSettingsController, :update
      get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
      live "/users", UsersLive.Index, :index
      live "/users/new", UsersLive.Index, :new
      live "/users/:id/edit", UsersLive.Index, :edit

      live "/series", SeriesLive.Index, :index
      live "/series/new", SeriesLive.Index, :new
      live "/series/:id/edit", SeriesLive.Index, :edit

      live "/taxes", TaxesLive.Index, :index
      live "/taxes/new", TaxesLive.Index, :new
      live "/taxes/:id/edit", TaxesLive.Index, :edit

      live "/invoices/new", InvoicesLive.Edit, :new
      live "/invoices/:id/new", InvoicesLive.Edit, :new
      live "/invoices/:id/edit", InvoicesLive.Edit, :edit
      get "/invoices/:id/show", PageController, :show_invoice
      live "/invoices", InvoicesLive.Index, :index
      live "/customers/:customer_id/invoices", InvoicesLive.Index, :customer
      get "/invoices/:id/download", PageController, :download
      get "/invoices/download/*ids", PageController, :download
      get "/invoices/:id/send_email", PageController, :send_email

      live "/customers/new", CustomersLive.Edit, :new
      live "/customers/:id/edit", CustomersLive.Edit, :edit
      live "/customers/", CustomersLive.Index, :index

      live "/templates", TemplatesLive.Index, :index
      live "/templates/new", TemplatesLive.Edit, :new
      live "/templates/:id/edit", TemplatesLive.Edit, :edit

      live "/recurring_invoices", RecurringInvoicesLive.Index, :index
      live "/recurring_invoices/new", RecurringInvoicesLive.Edit, :new
      live "/recurring_invoices/:id/edit", RecurringInvoicesLive.Edit, :edit

      get "/settings", SettingsController, :edit
      post "/settings", SettingsController, :update

      get "/iframe/:id", IframeController, :iframe

      get "/csv", PageController, :csv
    end
  end

  scope "/", SiwappWeb do
    pipe_through [:browser]
    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end
