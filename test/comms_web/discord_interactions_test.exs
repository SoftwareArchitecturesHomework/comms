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

    test "handles /projects command", %{conn: conn} do
      # Slash command interaction (type 2) for /projects
      params = %{
        "type" => 2,
        "data" => %{
          "name" => "projects",
          "options" => []
        },
        "member" => %{
          "user" => %{
            "id" => "214101395215876107"
          }
        }
      }

      conn = post(conn, "/api/discord/interactions", params)

      response = json_response(conn, 200)
      assert response["type"] == 4
      assert is_binary(response["data"]["content"])
      # Should either show projects or an error message about core service
      assert response["data"]["content"] =~ ~r/(projects|Error|Core service)/i
    end
  end
end
