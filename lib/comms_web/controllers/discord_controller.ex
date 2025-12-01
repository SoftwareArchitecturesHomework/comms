defmodule CommsWeb.DiscordController do
  use CommsWeb, :controller

  alias Comms.Discord
  alias Comms.Discord.Commands

  def notify(conn, params) do
    with {:ok, channel_id} <- fetch_string(params, "channel_id"),
         {:ok, content} <- fetch_string(params, "content"),
         {:ok, _} <- Discord.send_message(channel_id, content) do
      json(conn, %{ok: true})
    else
      {:error, :missing_token} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{error: "Missing DISCORD_BOT_TOKEN"})

      {:error, {:http_error, status, body}} ->
        conn
        |> put_status(status)
        |> json(%{error: body})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  defp fetch_string(map, key) do
    case Map.get(map, key) do
      val when is_binary(val) and byte_size(val) > 0 -> {:ok, val}
      _ -> {:error, {:invalid, key}}
    end
  end

  defp build_content_from_command("projects", _options), do: "/projects"

  defp build_content_from_command("task", options) do
    proj = get_option(options, "project_id")
    name = get_option(options, "name")
    "/task #{proj} #{name}"
  end

  defp build_content_from_command("invite", options) do
    task_id = get_option(options, "task_id")
    users = get_option(options, "users")
    "/invite #{task_id} #{users}"
  end

  defp build_content_from_command(other, _options), do: other || ""

  defp get_option(list, key) when is_list(list) do
    case Enum.find(list, fn opt ->
           opt["name"] == key or (is_map(opt) && Map.get(opt, :name) == key)
         end) do
      nil -> ""
      opt -> opt["value"] || Map.get(opt, :value) || ""
    end
  end

  # Note: PING interactions (type 1) are handled in the VerifyDiscordSignature plug
  # and never reach this controller, matching Discord's JavaScript middleware behavior.

  # Interactions endpoint: handle slash commands (type 2)
  def interactions(conn, %{"type" => 2, "data" => data}) do
    name = data["name"] || Map.get(data, :name)
    options = data["options"] || Map.get(data, :options) || []
    content = build_content_from_command(name, options)

    case Commands.handle(content) do
      {:ok, response_text} ->
        # Respond with CHANNEL_MESSAGE_WITH_SOURCE (type 4)
        json(conn, %{type: 4, data: %{content: response_text}})

      {:error, reason} ->
        # Respond with an error message visible to the user
        json(conn, %{
          type: 4,
          data: %{
            content: "Error: #{inspect(reason)}",
            flags: 64  # EPHEMERAL flag - only visible to user
          }
        })
    end
  end

  # Fallback for unknown interaction types
  def interactions(conn, params) do
    require Logger
    Logger.warning("Unknown Discord interaction: #{inspect(params)}")

    conn
    |> put_status(:bad_request)
    |> json(%{error: "Unknown interaction type"})
  end
end
