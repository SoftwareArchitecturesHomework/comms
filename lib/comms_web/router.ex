defmodule CommsWeb.Router do
  use CommsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CommsWeb.Plugs.VerifyJWT
  end

  pipeline :discord do
    plug :accepts, ["json"]
    plug Plug.Parsers, parsers: [:json], json_decoder: Jason
    plug CommsWeb.Plugs.VerifyDiscordSignature
  end

  scope "/api", CommsWeb do
    pipe_through :api

    # Notification endpoints mapped from CommsService RPCs
    post "/notifications/user-added", NotificationController, :user_added
    post "/notifications/user-removed", NotificationController, :user_removed
    post "/notifications/project-completed", NotificationController, :project_completed
    post "/notifications/task-assigned", NotificationController, :task_assigned
    post "/notifications/task-completed", NotificationController, :task_completed

    post "/notifications/task-permission-request",
         NotificationController,
         :task_permission_request

    # Discord integration
    post "/discord/notify", DiscordController, :notify
  end

  scope "/api", CommsWeb do
    pipe_through :discord

    post "/discord/interactions", DiscordController, :interactions
  end

  scope "/", CommsWeb do
    get "/health", HealthController, :check
  end
end
