defmodule CommsWeb.Plugs.VerifyDiscordSignature do
  @moduledoc """
  Verifies Discord interaction requests using Ed25519 signatures.

  Discord sends headers:
  - "X-Signature-Ed25519": hex-encoded signature
  - "X-Signature-Timestamp": timestamp string

  The signed message is `timestamp <> raw_body`.

  Set `DISCORD_PUBLIC_KEY` to Discord application's public key (hex).

  To disable verification (e.g., tests), set `DISCORD_SIGNATURE_DISABLE=1`.

  Note: PING interactions (type 1) are handled directly in this plug,
  matching Discord's JavaScript middleware behavior. They never reach the controller.
  """

  import Plug.Conn
  require Logger

  defp discord_public_key, do: Application.get_env(:comms, :discord_public_key)
  defp signature_disabled?, do: Application.get_env(:comms, :discord_signature_disable, false)

  def init(opts), do: opts

  def call(conn, _opts) do
    if signature_disabled?() do
      # Skip verification but still handle PING
      handle_interaction(conn)
    else
      # Try to get raw_body from assigns, or reconstruct from body_params
      raw_body =
        case Map.get(conn.assigns, :raw_body) do
          nil ->
            Logger.warning("raw_body not found in assigns, reconstructing from body_params")
            # Reconstruct the raw body from parsed JSON (as Discord's JS middleware does)
            Jason.encode!(conn.body_params)

          body when is_binary(body) ->
            body
        end

      Logger.debug(
        "Raw body for verification (length: #{byte_size(raw_body)}): #{String.slice(raw_body, 0, 100)}..."
      )

      with [sig_hex] <- get_req_header(conn, "x-signature-ed25519"),
           [timestamp] <- get_req_header(conn, "x-signature-timestamp"),
           {:ok, public_key} <- fetch_public_key(),
           {:ok, signature} <- decode_hex(sig_hex),
           true <- verify(timestamp <> raw_body, signature, public_key) do
        # Signature is valid, now handle the interaction
        handle_interaction(conn)
      else
        error ->
          Logger.error("=== DISCORD SIGNATURE VERIFICATION FAILED ===")
          Logger.error("Error: #{inspect(error)}")

          Logger.error(
            "Headers: #{inspect(get_req_header(conn, "x-signature-ed25519"))} / #{inspect(get_req_header(conn, "x-signature-timestamp"))}"
          )

          Logger.error(
            "Raw body present in assigns: #{inspect(Map.has_key?(conn.assigns, :raw_body))}"
          )

          conn
          |> put_status(:unauthorized)
          |> Phoenix.Controller.json(%{error: "Invalid discord signature"})
          |> halt()
      end
    end
  end

  # Handle PING interactions immediately in the plug (like Discord's JS middleware)
  defp handle_interaction(conn) do
    # Check if this is a PING interaction (type 1)
    type = Map.get(conn.body_params, "type")

    Logger.info("=== DISCORD INTERACTION ===")
    Logger.info("Type: #{inspect(type)}")
    Logger.info("Body params keys: #{inspect(Map.keys(conn.body_params))}")

    if type == 1 do
      response_body = Jason.encode!(%{type: 1})
      Logger.info("Responding with PONG: #{response_body}")
      Logger.info("Content-Type: application/json")

      # Respond with PONG immediately
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{type: 1}))
      |> halt()
    else
      # Not a PING, continue to controller
      conn
    end
  end

  defp fetch_public_key do
    case discord_public_key() do
      nil -> {:error, :missing_public_key}
      hex when is_binary(hex) -> decode_hex(hex)
    end
  end

  defp decode_hex(hex) do
    try do
      {:ok, Base.decode16!(hex, case: :mixed)}
    rescue
      _ -> {:error, :bad_hex}
    end
  end

  # Verify Ed25519 using :crypto (OTP 24+). Discord uses pure Ed25519 over message.
  defp verify(message, signature, public_key) when is_binary(message) do
    try do
      # OTP 24+ format for EdDSA verification
      :crypto.verify(:eddsa, :none, message, signature, [public_key, :ed25519])
    rescue
      e ->
        Logger.warning("Ed25519 verify failed: #{inspect(e)}")
        false
    end
  end
end
