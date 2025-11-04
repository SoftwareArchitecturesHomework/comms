defmodule CommsWeb.Plugs.VerifyJWT do
    @moduledoc """
    Plug to verify JWT tokens from the Authorization header.

    This is a placeholder implementation. You'll need to add a JWT library
    like `joken` or `guardian` to fully implement this.

    Usage in router:

        pipeline :authenticated do
            plug :accepts, ["json"]
            plug CommsWeb.Plugs.VerifyJWT
        end

        scope "/api", CommsWeb do
            pipe_through [:api, :authenticated]

            post "/emails", EmailController, :send_email
        end
    """

    import Plug.Conn
    require Logger

    def init(opts), do: opts

    def call(conn, _opts) do
        case get_req_header(conn, "authorization") do
        ["Bearer " <> token] ->
            verify_token(conn, token)

        _ ->
            conn
            |> put_status(:unauthorized)
            |> Phoenix.Controller.json(%{error: "Missing or invalid authorization header"})
            |> halt()
        end
    end

    defp verify_token(conn, token) do
        # TODO: Implement actual JWT verification here
        # For now, this is a placeholder that accepts any token
        Logger.debug("JWT verification called with token: #{String.slice(token, 0..10)}...")

        # Example of what you'd do with a real JWT library:
        # case Joken.verify(token, signer) do
        #   {:ok, claims} ->
        #     assign(conn, :current_user_claims, claims)
        #   {:error, _reason} ->
        #     conn
        #     |> put_status(:unauthorized)
        #     |> Phoenix.Controller.json(%{error: "Invalid token"})
        #     |> halt()
        # end

        # For now, just pass through with a warning
        Logger.warning("JWT verification is not implemented yet - allowing all requests")
        assign(conn, :jwt_verified, true)
    end
end
