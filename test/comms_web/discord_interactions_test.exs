defmodule CommsWeb.DiscordInteractionsTest do
  use CommsWeb.ConnCase, async: true

  describe "Discord interactions endpoint" do
    test "responds to PING with PONG", %{conn: conn} do
      # Discord sends a PING (type 1) to verify the endpoint
      params = %{"type" => 1}
      conn = post(conn, "/api/discord/interactions", params)

      response = json_response(conn, 200)
      assert response["type"] == 1
    end

    test "responds to PING with integer type", %{conn: conn} do
      # Discord may send type as integer
      params = %{type: 1}
      conn = post(conn, "/api/discord/interactions", params)

      response = json_response(conn, 200)
      assert response["type"] == 1
    end
  end
end
