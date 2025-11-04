defmodule CommsWeb.UserSocket do
    use Phoenix.Socket

    # Channels
    channel "discord:*", CommsWeb.DiscordChannel

    @impl true
    def connect(%{"token" => token}, socket, _connect_info) do
        # TODO: Implement token verification here
        # For now, accept any token
        {:ok, assign(socket, :token, token)}
    end

    @impl true
    def connect(_params, _socket, _connect_info) do
        :error
    end

    @impl true
    def id(socket), do: "user_socket:#{socket.assigns.token}"
end
