import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## JWT Configuration
#
# For asymmetric JWT verification, provide the public key.
# The key should be in PEM format (RSA, ECDSA, etc.)
if jwt_public_key = System.get_env("JWT_PUBLIC_KEY") do
  config :comms, :jwt_public_key, jwt_public_key
end

config :comms, :jwt_debug, System.get_env("JWT_DEBUG") == "1"

# ## Discord Configuration
if discord_public_key = System.get_env("DISCORD_PUBLIC_KEY") do
  config :comms, :discord_public_key, discord_public_key
end

if discord_bot_token = System.get_env("DISCORD_BOT_TOKEN") do
  config :comms, :discord_bot_token, discord_bot_token
end

if discord_app_id = System.get_env("DISCORD_APP_ID") do
  config :comms, :discord_app_id, discord_app_id
end

# Only set signature disable in runtime if not already configured (e.g., by test.exs)
if config_env() != :test do
  config :comms, :discord_signature_disable, System.get_env("DISCORD_SIGNATURE_DISABLE") == "1"
end

# ## Core Service Configuration
if core_service_url = System.get_env("CORE_SERVICE_HTTP") do
  config :comms, :core_service_url, core_service_url
end

if smtp_username = System.get_env("SMTP_USERNAME") do
  config :comms, :smtp_from_email, smtp_username
end

# ## Email Configuration
#
# Compute email template paths at runtime to support both dev and release environments
layout_path =
  try do
    path = Application.app_dir(:comms, "priv/templates/email/layout.html.eex")
    if File.exists?(path), do: path, else: "priv/templates/email/layout.html.eex"
  rescue
    _ -> "priv/templates/email/layout.html.eex"
  end

templates_path =
  try do
    path = Application.app_dir(:comms, "priv/templates/email")
    if File.exists?(path), do: path, else: "priv/templates/email"
  rescue
    _ -> "priv/templates/email"
  end

config :comms, :email_layout_path, layout_path
config :comms, :email_templates_path, templates_path

# ## SMTP Configuration
#
# Configure SMTP settings from environment variables for all environments
if smtp_server = System.get_env("SMTP_SERVER") do
  ssl = System.get_env("SMTP_SSL") == "true"
  port = String.to_integer(System.get_env("SMTP_PORT") || if(ssl, do: "465", else: "587"))
  verify_mode_env = System.get_env("SMTP_TLS_VERIFY")

  verify_mode =
    case verify_mode_env do
      nil -> :verify_peer
      "false" -> :verify_none
      "0" -> :verify_none
      "true" -> :verify_peer
      "1" -> :verify_peer
      _ -> :verify_peer
    end

  cacertfile = System.get_env("SMTP_CACERTFILE")

  config :comms, Comms.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: smtp_server,
    username: System.get_env("SMTP_USERNAME"),
    password: System.get_env("SMTP_PASSWORD"),
    port: port,
    ssl: ssl,
    auth: :always,
    tls: if(not ssl, do: :always, else: :never),
    retries: 3,
    no_mx_lookups: true,
    tls_options:
      Enum.reject(
        [
          {:verify, verify_mode},
          {:depth, 3},
          cacertfile && {:cacertfile, cacertfile}
        ],
        &(!&1)
      )
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/comms start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :comms, CommsWeb.Endpoint, server: true
end

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

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :comms, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :comms, CommsWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :comms, CommsWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :comms, CommsWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :comms, Comms.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
