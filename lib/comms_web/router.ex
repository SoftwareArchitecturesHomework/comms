defmodule CommsWeb.Router do
  use CommsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CommsWeb do
    pipe_through :api

    # API routes will go here
    # Email endpoint
    # Discord bot endpoint
  end

  # Health check endpoint (no pipeline needed)
  scope "/", CommsWeb do
    get "/health", HealthController, :check
  end
end
