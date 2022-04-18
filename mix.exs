defmodule Siwapp.MixProject do
  use Mix.Project

  def project do
    [
      app: :siwapp,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: [
        groups_for_modules: [
          Context: [
            Siwapp.Accounts,
            Siwapp.Invoices,
            Siwapp.RecurringInvoices,
            Siwapp.Customers,
            Siwapp.Settings,
            Siwapp.Templates,
            Siwapp.Commons
          ],
          Invoices: [
            Siwapp.Invoices.Invoice,
            Siwapp.Invoices.Payment,
            Siwapp.Invoices.Item,
            Siwapp.Invoices.InvoiceQuery,
            Siwapp.Invoices.AmountHelper,
            Siwapp.Invoices.Statistics
          ],
          Customers: [Siwapp.Customers.Customer, Siwapp.Customers.CustomerQuery],
          "Recurring Invoices": [
            Siwapp.RecurringInvoices.RecurringInvoice,
            Siwapp.RecurringInvoices.RecurringInvoiceQuery
          ],
          Commons: [Siwapp.Commons.Series, Siwapp.Commons.Tax],
          Accounts: [Siwapp.Accounts.User],
          Settings: [Siwapp.Settings.Setting, Siwapp.Settings.SettingBundle],
          Templates: [Siwapp.Templates.Template],
          Searches: [Siwapp.Searches.Search, Siwapp.Searches.SearchQuery],
          Controllers: [
            SiwappWeb.IframeController,
            SiwappWeb.PageController,
            SiwappWeb.SettingsController,
            SiwappWeb.UserConfirmationController,
            SiwappWeb.UserResetPasswordController,
            SiwappWeb.UserSessionController,
            SiwappWeb.UserSettingsController,
            SiwappWeb.Api.InvoicesController,
            SiwappWeb.Api.TokenController
          ],
          GraphQL: [
            SiwappWeb.Resolvers.Customer,
            SiwappWeb.Resolvers.Invoice,
            SiwappWeb.Resolvers.Errors,
            SiwappWeb.Schema.Helpers
          ],
          Views: [
            SiwappWeb.LayoutView,
            SiwappWeb.PageView,
            SiwappWeb.ErrorHelpers,
            SiwappWeb.GraphicHelpers
          ]
        ],
        extras: ["README.md"],
        logo: "#{__DIR__}/priv/static/images/logo.svg"
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Siwapp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe, "~> 1.7"},
      {:absinthe_plug, "~> 1.5"},
      {:bcrypt_elixir, "~> 2.0"},
      {:bulma, "0.9.3"},
      {:chromic_pdf, "~> 1.1"},
      {:contex, "~> 0.4.0"},
      {:cachex, "~> 3.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:csv, "~> 2.4"},
      {:dart_sass, "~> 0.3", runtime: Mix.env() == :dev},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ecto_sql, "~> 3.6"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:faker, "~> 0.17.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.18"},
      {:gen_smtp, "~> 1.0"},
      {:hackney, "~> 1.8"},
      {:heex_formatter, github: "feliperenan/heex_formatter"},
      {:jason, "~> 1.2"},
      {:mappable, "~> 0.2.4"},
      {:money, "~> 1.4"},
      {:phoenix, "~> 1.6.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:sentry, "~> 8.0"},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"}
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
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "sass default --no-source-map --style=compressed",
        "esbuild default --minify",
        "phx.digest"
      ],
      sentry_recompile: ["compile", "deps.compile sentry --force"]
    ]
  end
end
