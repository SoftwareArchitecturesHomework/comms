defmodule CommsWeb.DiscordChannel do
    @moduledoc """
    Channel for Discord bot communication via WebSocket.

    The Discord bot can connect to this channel to receive real-time updates
    and send messages.

    Usage from Discord bot (using Phoenix Channels client):

        // JavaScript example
        const socket = new Socket("/socket", {params: {token: "bot_token"}})
        socket.connect()

        const channel = socket.channel("discord:lobby", {})
        channel.join()
            .receive("ok", resp => { console.log("Joined successfully", resp) })
            .receive("error", resp => { console.log("Unable to join", resp) })

        // Listen for messages
        channel.on("new_message", payload => {
            console.log("New message:", payload)
        })

        // Send a message
        channel.push("send_message", {content: "Hello from bot"})
    """

    use CommsWeb, :channel
    require Logger

    @impl true
    def join("discord:lobby", _payload, socket) do
        # TODO: Add authentication/authorization here
        Logger.info("Discord bot joined the lobby")
        {:ok, %{message: "Welcome to the Discord channel"}, socket}
    end

    @impl true
    def join("discord:" <> _private_room_id, _params, _socket) do
        {:error, %{reason: "unauthorized"}}
    end

    @impl true
    def handle_in("send_message", %{"content" => content}, socket) do
        Logger.info("Received message from Discord bot: #{content}")

        # Broadcast the message to all connected clients
        broadcast(socket, "new_message", %{
            content: content,
            timestamp: DateTime.utc_now()
        })

        {:reply, {:ok, %{status: "sent"}}, socket}
    end

    @impl true
    def handle_in("send_message", _payload, socket) do
        {:reply, {:error, %{reason: "content is required"}}, socket}
    end

    @impl true
    def handle_in(event, payload, socket) do
        Logger.warning("Unhandled event: #{event} with payload: #{inspect(payload)}")
        {:reply, {:error, %{reason: "unknown event"}}, socket}
    end
end
