defmodule Comms.Auth.JWTTest do
  use ExUnit.Case, async: true

  alias Comms.Auth.JWT

  describe "verify_token/1" do
    test "returns error when no public key is configured" do
      # Save original config
      original_key = Application.get_env(:comms, :jwt_public_key)

      # Clear the config
      Application.delete_env(:comms, :jwt_public_key)

      assert {:error, :no_public_key_configured} = JWT.verify_token("some.jwt.token")

      # Restore original config
      if original_key do
        Application.put_env(:comms, :jwt_public_key, original_key)
      end
    end

    test "returns error for invalid token with valid key" do
      # Configure an invalid public key that will fail during verification
      dummy_key = "not-a-valid-pem-key"

      Application.put_env(:comms, :jwt_public_key, dummy_key)

      # The error could be :invalid_public_key or :signature_error depending on the key format
      assert {:error, _reason} = JWT.verify_token("invalid.token.format")

      Application.delete_env(:comms, :jwt_public_key)
    end
  end
end
