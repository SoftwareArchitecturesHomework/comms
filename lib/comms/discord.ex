defmodule Comms.Discord do
  @moduledoc """
  Minimal Discord client using Req for sending messages.

  Relies on `DISCORD_BOT_TOKEN` env var.
  """

  @discord_api "https://discord.com/api/v10"

  def send_message(channel_id, content) when is_binary(channel_id) and is_binary(content) do
    token = Application.get_env(:comms, :discord_bot_token)

    if is_nil(token) or token == "" do
      {:error, :missing_token}
    else
      req =
        Req.new(
          headers: [
            {"Authorization", "Bot " <> token},
            {"Content-Type", "application/json"}
          ]
        )

      body = %{content: content}

      case Req.post(req, url: "#{@discord_api}/channels/#{channel_id}/messages", json: body) do
        {:ok, %Req.Response{status: status} = resp} when status in 200..299 ->
          {:ok, resp.body}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
