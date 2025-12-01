defmodule Comms.Discord.Commands do
  @moduledoc """
  Simple parser/handler for Discord text commands used by interactions endpoint.

  Supported commands:
  - /projects -> replies with 'hello'
  - /task {project_id} {name} -> replies with a random task_id
  - /invite {task_id} {...users} -> replies with an acknowledgement
  """

  @spec handle(String.t()) :: {:ok, String.t()} | {:error, term()}
  def handle(content) when is_binary(content) do
    content
    |> String.trim()
    |> String.split(~r/\s+/, parts: 2)
    |> case do
      ["/projects"] ->
        {:ok, "hello"}

      ["/task", rest] ->
        handle_task(rest)

      ["/invite", rest] ->
        handle_invite(rest)

      [unknown | _] ->
        {:ok, "Unknown command: #{unknown}"}

      _ ->
        {:error, :invalid_content}
    end
  end

  defp handle_task(rest) do
    # Expect: {project_id} {name}
    case String.split(rest, ~r/\s+/, parts: 2) do
      [project_id, name] when project_id != "" and name != "" ->
        task_id = :rand.uniform(1_000_000)
        {:ok, "Created task ##{task_id} for project #{project_id}: #{name}"}

      _ ->
        {:ok, "Usage: /task {project_id} {name}"}
    end
  end

  defp handle_invite(rest) do
    # Expect: {task_id} {...users}
    case String.split(rest, ~r/\s+/, parts: 2) do
      [task_id, users_str] when task_id != "" and users_str != "" ->
        users =
          users_str
          |> String.split(~r/\s+/, trim: true)
          |> Enum.map(&String.trim_leading(&1, "@"))
          |> Enum.reject(&(&1 == ""))

        if users == [] do
          {:ok, "Usage: /invite {task_id} {@user1 @user2 ...}"}
        else
          {:ok, "Invited #{Enum.join(users, ", ")} to task #{task_id}"}
        end

      _ ->
        {:ok, "Usage: /invite {task_id} {@user1 @user2 ...}"}
    end
  end
end
