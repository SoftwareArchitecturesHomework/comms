defmodule Comms.Release do
  @moduledoc """
  Entry point for release tasks (migrations, discord commands)
  run via `eval` commands in Docker.
  """
  require Logger

  def install_discord_commands do
    Application.ensure_all_started(:comms)

    case Comms.Discord.Registrar.install_global_commands() do
      {:ok, _body} ->
        Logger.info("✅ Discord commands installed successfully")

      {:error, reason} ->
        # Log error but don't crash the container startup;
        # allow the server to boot even if Discord fails.
        Logger.warning("⚠️ Failed to install Discord commands: #{inspect(reason)}")
    end
  end
end
