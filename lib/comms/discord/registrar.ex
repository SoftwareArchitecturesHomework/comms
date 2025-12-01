defmodule Comms.Discord.Registrar do
  @moduledoc """
  Registers Discord application commands using the Discord REST API.

  Uses `Req` and requires `DISCORD_BOT_TOKEN` and `APP_ID` env vars.
  """

  @discord_api "https://discord.com/api/v10"

  defp app_id, do: Application.get_env(:comms, :discord_app_id)
  defp bot_token, do: Application.get_env(:comms, :discord_bot_token)

  def install_global_commands(app_id \\ nil) do
    app_id = app_id || app_id()
    token = bot_token()

    with {:ok, _} <- ensure_env(app_id, token) do
      req =
        Req.new(
          headers: [
            {"Authorization", "Bot " <> token},
            {"Content-Type", "application/json"}
          ]
        )

      commands = build_commands()

      case Req.put(req, url: "#{@discord_api}/applications/#{app_id}/commands", json: commands) do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp ensure_env(app_id, token) do
    cond do
      is_nil(app_id) or app_id == "" -> {:error, :missing_app_id}
      is_nil(token) or token == "" -> {:error, :missing_token}
      true -> {:ok, :env_ok}
    end
  end

  # Command specs aligned with the JS example and our parser.
  defp build_commands do
    [
      %{
        name: "projects",
        description: "List projects (placeholder)",
        type: 1,
        integration_types: [0, 1],
        contexts: [0, 1, 2]
      },
      %{
        name: "task",
        description: "Create a task (placeholder)",
        options: [
          %{
            type: 3,
            name: "project_id",
            description: "Project ID",
            required: true
          },
          %{
            type: 3,
            name: "name",
            description: "Task name",
            required: true
          }
        ],
        type: 1,
        integration_types: [0, 1],
        contexts: [0, 2]
      },
      %{
        name: "invite",
        description: "Invite users to a task (placeholder)",
        options: [
          %{
            type: 3,
            name: "task_id",
            description: "Task ID",
            required: true
          },
          %{
            type: 3,
            name: "users",
            description: "Space-separated users (@alice @bob)",
            required: true
          }
        ],
        type: 1,
        integration_types: [0, 1],
        contexts: [0, 2]
      }
    ]
  end
end
