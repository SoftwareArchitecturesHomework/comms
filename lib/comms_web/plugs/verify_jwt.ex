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

          # protected routes here
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
    pem = Application.get_env(:comms, :jwt_public_key) |> normalize_pem()

    if is_nil(pem) or pem == "" do
      Logger.warning("JWT_PUBLIC_KEY not configured")
      return_unauthorized(conn, "Invalid token")
    else
      signer = Joken.Signer.create("RS256", %{"pem" => pem})

      case Joken.verify(token, signer) do
        {:ok, claims} ->
          debug_log(token, claims)
          assign(conn, :claims, claims)

        {:error, reason} ->
          Logger.warning("JWT verification failed: #{inspect(reason)}")
          debug_log(token, :error)
          return_unauthorized(conn, "Invalid token")
      end
    end
  end

  defp return_unauthorized(conn, message) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{error: message})
    |> halt()
  end

  # Support either real newlines or escaped \n sequences in the env var.
  defp normalize_pem(nil), do: nil

  defp normalize_pem(pem) do
    pem
    |> String.replace("\\n", "\n")
    |> String.trim()
  end

  defp debug_log(token, result) do
    if Application.get_env(:comms, :jwt_debug, false) do
      with [header_b64, _payload_b64 | _] <- String.split(token, "."),
           {:ok, header_json} <- base64url_decode_json(header_b64) do
        Logger.debug("JWT header: #{inspect(header_json)} result=#{inspect(result)}")
      else
        _ -> Logger.debug("JWT header decode failed")
      end
    end
  end

  defp base64url_decode_json(b64) do
    # Add padding if missing
    padded = pad_base64(b64)

    case Base.url_decode64(padded, padding: true) do
      {:ok, raw} -> Jason.decode(raw)
      :error -> {:error, :bad_base64}
    end
  end

  defp pad_base64(b64) do
    rem = rem(String.length(b64), 4)
    if rem == 0, do: b64, else: b64 <> String.duplicate("=", 4 - rem)
  end
end
