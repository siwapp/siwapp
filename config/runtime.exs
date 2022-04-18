import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :siwapp, SiwappWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :siwapp, SiwappWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer

  mailer = System.get_env("MAILER")
  mailer_adapters = String.to_atom("Elixir.Swoosh.Adapters.#{mailer}")
  mailers_only_api_key = ["Dyn", "MailPace", "Mandrill", "Postmark", "Sendgrid", "Sendinblue"]
  mailers_api_key = mailers_only_api_key ++ ["Mailjet", "Mailgun", "SocketLabs", "SparkPost"]

  cond do
    Enum.member?(mailers_api_key, mailer) ->
      api_key = System.get_env("MAILER_API_KEY")

      if Enum.member?(mailers_only_api_key, mailer) do
        config :siwapp, Siwapp.Mailer,
          adapter: mailer_adapters,
          api_key: api_key
      else
        case mailer do
          "Mailjet" ->
            config :siwapp, Siwapp.Mailer,
              adapter: mailer_adapters,
              api_key: api_key,
              secret: System.get_env("MAILER_SECRET_KEY")

          "Mailgun" ->
            config :siwapp, Siwapp.Mailer,
              adapter: mailer_adapters,
              api_key: api_key,
              domain: System.get_env("MAILER_DOMAIN"),
              base_url: System.get_env("MAILER_BASE_URL")

          "SocketLabs" ->
            config :siwapp, Siwapp.Mailer,
              adapter: mailer_adapters,
              api_key: api_key,
              server_id: System.get_env("MAILER_SERVER_ID")

          "SparkPost" ->
            config :siwapp, Siwapp.Mailer,
              adapter: mailer_adapters,
              api_key: api_key,
              endpoint: System.get_env("MAILER_ENDPOINT")
        end
      end

    mailer == "AmazonSES" ->
      config :siwapp, Siwapp.Mailer,
        adapter: mailer_adapters,
        region: System.get_env("MAILER_REGION_ENDPOINT"),
        access_key: System.get_env("MAILER_ACCESS_KEY"),
        secret: System.get_env("MAILER_SECRET_KEY")

    mailer == "Gmail" ->
      config :siwapp, Siwapp.Mailer,
        adapter: mailer_adapters,
        access_token: System.get_env("GMAIL_API_ACCESS_TOKEN")

    mailer == "Sendmail" ->
      config :siwapp, Siwapp.Mailer,
        adapter: mailer_adapters,
        cmd_path: System.get_env("MAILER_CMD_PATH"),
        cmd_args: "-N delay,failure,success",
        qmail: true

    mailer == "SMTP" ->
      config :siwapp, Siwapp.Mailer,
        adapter: mailer_adapters,
        relay: System.get_env("SMTP_DOMAIN"),
        username: System.get_env("SMTP_USER"),
        password: System.get_env("SMTP_PASSWORD"),
        ssl: true,
        tls: System.get_env("SMTP_ENABLE_STARTTLS_AUTO"),
        auth: System.get_env("SMTP_AUTHENTICATION"),
        port: System.get_env("SMTP_PORT"),
        hostname: System.get_env("SMTP_HOST")

    true ->
      config :siwapp, Siwapp.Mailer, adapter: Swoosh.Adapters.Local
  end

  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
