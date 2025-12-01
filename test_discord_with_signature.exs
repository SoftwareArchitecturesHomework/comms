#!/usr/bin/env elixir

# Script to test Discord interactions endpoint with proper Ed25519 signatures
# Run with: elixir test_discord_with_signature.exs

Mix.install([
  {:req, "~> 0.4"}
])

defmodule DiscordSignatureTest do
  @moduledoc """
  Test the Discord interactions endpoint with proper Ed25519 signatures.
  This simulates what Discord actually sends to our endpoint.
  """

  def run do
    # Generate a test keypair
    {public_key, private_key} = generate_keypair()

    # Convert public key to hex for environment variable
    public_key_hex = Base.encode16(public_key, case: :lower)

    IO.puts("Generated test keypair:")
    IO.puts("Public Key (hex): #{public_key_hex}")
    IO.puts("")
    IO.puts("Set this environment variable:")
    IO.puts("export DISCORD_PUBLIC_KEY=#{public_key_hex}")
    IO.puts("")

    # Create a PING request
    body = Jason.encode!(%{"type" => 1})
    timestamp = "#{:os.system_time(:second)}"

    # Sign the message (timestamp + body)
    message = timestamp <> body
    signature = :crypto.sign(:eddsa, :none, message, [private_key, :ed25519])
    signature_hex = Base.encode16(signature, case: :lower)

    IO.puts("Testing PING interaction with signature...")
    IO.puts("Timestamp: #{timestamp}")
    IO.puts("Body: #{body}")
    IO.puts("Signature: #{signature_hex}")
    IO.puts("")

    # Make the request
    url = "http://localhost:4000/api/discord/interactions"

    headers = [
      {"content-type", "application/json"},
      {"x-signature-ed25519", signature_hex},
      {"x-signature-timestamp", timestamp}
    ]

    case Req.post(url, headers: headers, body: body) do
      {:ok, %{status: 200, body: response_body}} ->
        IO.puts("✅ SUCCESS!")
        IO.puts("Response: #{inspect(response_body)}")
        :ok

      {:ok, %{status: status, body: body}} ->
        IO.puts("❌ FAILED with status #{status}")
        IO.puts("Response: #{inspect(body)}")
        :error

      {:error, error} ->
        IO.puts("❌ ERROR: #{inspect(error)}")
        :error
    end
  end

  defp generate_keypair do
    # Generate Ed25519 keypair
    {public_key, private_key} = :crypto.generate_key(:eddsa, :ed25519)
    {public_key, private_key}
  end
end

DiscordSignatureTest.run()
