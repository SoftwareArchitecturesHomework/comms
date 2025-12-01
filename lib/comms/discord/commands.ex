defmodule Comms.Discord.Commands do
  @moduledoc """
  Simple parser/handler for Discord text commands used by interactions endpoint.

  Supported commands:
  - /projects -> fetches projects for the user from core service
  - /task {project_id} {name} -> replies with a random task_id
  - /invite {task_id} {...users} -> replies with an acknowledgement
  """

  @spec handle(String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, term()}
  def handle(content, user_id \\ nil)

  def handle(content, user_id) when is_binary(content) do
    content
    |> String.trim()
    |> String.split(~r/\s+/, parts: 2)
    |> case do
      ["/projects"] ->
        handle_projects(user_id)

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

  defp handle_projects(nil) do
    {:ok, "Error: Unable to identify user"}
  end

  defp handle_projects(user_id) do
    core_service_url = Application.get_env(:comms, :core_service_url)

    if is_nil(core_service_url) or core_service_url == "" do
      {:ok, "Error: Core service not configured"}
    else
      case fetch_user_projects(core_service_url, user_id) do
        {:ok, []} ->
          {:ok, "You have no projects assigned."}

        {:ok, projects} ->
          project_list =
            projects
            |> Enum.map(fn proj ->
              "• #{proj["name"]} (ID: #{proj["id"]})"
            end)
            |> Enum.join("\n")

          {:ok, "Your projects:\n#{project_list}"}

        {:error, reason} ->
          {:ok, "Error fetching projects: #{inspect(reason)}"}
      end
    end
  end

  defp fetch_user_projects(base_url, user_id) do
    url = "#{base_url}/api/discord/projects"
    body = %{"id" => user_id}

    case Req.post(url: url, json: body) do
      {:ok, %Req.Response{status: 200, body: projects}} when is_list(projects) ->
        {:ok, projects}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
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
