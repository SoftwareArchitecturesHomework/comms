defmodule Comms.Auth.JWT do
  @moduledoc """
  JWT token verification using asymmetric keys.

  This module handles JWT token verification for incoming requests
  from other microservices. It uses the public key configured via
  the JWT_PUBLIC_KEY environment variable.
  """

  use Joken.Config

  @impl true
  def token_config do
    default_claims(skip: [:aud, :iss])
  end

  @doc """
  Verifies a JWT token using the configured public key.

  Returns {:ok, claims} on success, {:error, reason} on failure.

  ## Examples

      iex> verify_token("eyJ...")
      {:ok, %{"sub" => "user123", "exp" => 1234567890}}

      iex> verify_token("invalid")
      {:error, :invalid_token}
  """
  def verify_token(token) do
    with {:ok, public_key} <- get_public_key(),
         {:ok, signer} <- create_signer(public_key),
         {:ok, claims} <- verify_and_validate(token, signer) do
      {:ok, claims}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Verifies a JWT token and returns the claims, raising on error.
  """
  def verify_token!(token) do
    case verify_token(token) do
      {:ok, claims} -> claims
      {:error, reason} -> raise "JWT verification failed: #{inspect(reason)}"
    end
  end

  defp get_public_key do
    case Application.get_env(:comms, :jwt_public_key) do
      nil -> {:error, :no_public_key_configured}
      key -> {:ok, key}
    end
  end

  defp create_signer(public_key) do
    try do
      signer = Joken.Signer.create("RS256", %{"pem" => public_key})
      {:ok, signer}
    rescue
      _ -> {:error, :invalid_public_key}
    end
  end
end
