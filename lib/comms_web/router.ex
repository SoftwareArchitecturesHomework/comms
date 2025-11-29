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
    get "/email/test", EmailController, :send_test
    post "/emails", EmailController, :send_email
  end

  scope "/", CommsWeb do
    get "/health", HealthController, :check
  end
end
