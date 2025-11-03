defmodule CommsWeb.HealthControllerTest do
  use CommsWeb.ConnCase, async: true

  describe "GET /health" do
    test "returns ok status", %{conn: conn} do
      conn = get(conn, ~p"/health")
      assert json_response(conn, 200) == %{"status" => "ok", "service" => "comms"}
    end
  end
end
