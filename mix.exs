defmodule Siwapp.MixProject do
  use Mix.Project

  def project do
    [
      app: :siwapp,
      version: "0.1.1",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        siwapp: [
          include_erts: false,
          include_executables_for: [:unix]
        ]
      ],
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
      {:bulma, "~> 0.9"},
      {:chromic_pdf, "~> 1.15"},
      {:contex, "~> 0.5.0"},
      {:cachex, "~> 4.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:csv, "~> 3.2"},
      {:dart_sass, "~> 0.7", runtime: Mix.env() == :dev},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ecto_sql, "~> 3.11"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:faker, "~> 0.18"},
      {:finch, "~> 0.18"},
      {:floki, ">= 0.36.0", only: :test},
      {:gettext, "~> 1.0"},
      {:gen_smtp, "~> 1.3"},
      {:hackney, "~> 1.20"},
      {:html_sanitize_ex, "~> 1.4"},
      {:hut, "~> 1.4", manager: :rebar3, override: true},
      {:jason, "~> 1.4"},
      {:mappable, "~> 0.2.4"},
      {:money, "~> 1.12"},
      {:pbkdf2_elixir, "~> 2.2"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_view, "~> 2.0"},
      {:plug_cowboy, "~> 2.7"},
      {:postgrex, ">= 0.0.0"},
      {:prom_ex, "~> 1.9"},
      {:sentry, "~> 11.0"},
      {:swoosh, "~> 1.16"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.1"},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false}
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
      setup: ["deps.get", "compile", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "sass default --no-source-map --style=compressed",
        "esbuild default --minify",
        "phx.digest"
      ],
      consistency: [
        "cmd echo Formatting ...",
        "format",
        "cmd echo",
        "cmd echo Checking compile warnings ...",
        "compile --no-deps-check --force",
        "cmd echo",
        "cmd echo Checking Credo ...",
        "credo -A --ignore todo --mute-exit-status",
        "cmd echo",
        "cmd echo Checking Dialyzer ...",
        "dialyzer --quiet-with-result",
        "cmd echo",
        "cmd echo Sobelow scan ...",
        "sobelow --config"
      ],
      sentry_recompile: ["compile", "deps.compile sentry --force"]
    ]
  end
end
