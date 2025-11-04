defmodule CommsWeb.Router do
  use CommsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CommsWeb.Plugs.VerifyJWT
    plug CommsWeb.Plugs.ExtractClaims
  end

  scope "/api", CommsWeb do
    pipe_through :api

    # Email endpoint - other services can send emails via this API
    post "/emails", EmailController, :send_email

    # Discord bot endpoint (to be implemented)
    # post "/discord/webhook", DiscordController, :webhook
  end

  scope "/", CommsWeb do
    get "/health", HealthController, :check
  end
end
