defmodule CommsWeb.Plugs.ExtractClaims do
    @moduledoc """
    Plug to extract JWT claims and make them available in conn.assigns.

    This plug should be used after VerifyJWT in the pipeline.

    Usage:

        pipeline :authenticated do
            plug :accepts, ["json"]
            plug CommsWeb.Plugs.VerifyJWT
            plug CommsWeb.Plugs.ExtractClaims
        end

    Access claims in your controller:

        def my_action(conn, _params) do
            user_id = conn.assigns.claims["sub"]
            # ...
        end
    """

    import Plug.Conn
    require Logger

    def init(opts), do: opts

    def call(conn, _opts) do
        # TODO: Implement actual claims extraction here
        # (verification should already be done by VerifyJWT)

        # For now, this is a placeholder
        Logger.debug("Claims extraction called")

        # Example placeholder claims
        claims = %{
        "sub" => "user_123",
        "email" => "user@example.com",
        "roles" => ["user"]
        }

        assign(conn, :claims, claims)
    end
end
