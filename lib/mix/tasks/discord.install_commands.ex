defmodule Mix.Tasks.Discord.InstallCommands do
  use Mix.Task

  @shortdoc "Install (upsert) global Discord application commands"

  def run(_args) do
    Mix.Task.run("app.start")

    case Comms.Discord.Registrar.install_global_commands() do
      {:ok, _body} ->
        Mix.shell().info("Discord commands installed successfully")

      {:error, {:http_error, status, body}} ->
        Mix.raise("Failed to install Discord commands: status=#{status} body=#{inspect(body)}")

      {:error, :missing_app_id} ->
        Mix.raise("DISCORD_APP_ID environment variable is not set")

      {:error, :missing_token} ->
        Mix.raise("DISCORD_BOT_TOKEN environment variable is not set")

      {:error, reason} ->
        Mix.raise("Failed to install Discord commands: #{inspect(reason)}")
    end
  end
end
