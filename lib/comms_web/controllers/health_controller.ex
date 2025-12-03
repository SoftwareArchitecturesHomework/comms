defmodule CommsWeb.HealthController do
  use CommsWeb, :controller

  def check(conn, _params) do
    json(conn, %{
      status: "ok",
      service: "comms",
      random_emoji: Enum.random(["😀", "🚀", "🌟", "🔥", "💡", "🎉"])
    })
  end
end
