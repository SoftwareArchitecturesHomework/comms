defmodule Comms.Discord.Commands do
  @moduledoc """
  Simple parser/handler for Discord text commands used by interactions endpoint.

  Supported commands:
  - /projects -> fetches projects for the user from core service
  - /task {project_id} {name} -> creates a task in the specified project
  - /assign {task_id} @user -> assigns a task to a user
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
        handle_task(rest, user_id)

      ["/assign", rest] ->
        handle_assign(rest, user_id)

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

  defp handle_task(_, nil), do: {:ok, "Error: Unable to identify user"}

  defp handle_task(rest, user_id) do
    # Expect: {project_id} {name}
    case String.split(rest, ~r/\s+/, parts: 2) do
      [project_id, name] when project_id != "" and name != "" ->
        core_service_url = Application.get_env(:comms, :core_service_url)

        if is_nil(core_service_url) or core_service_url == "" do
          {:ok, "Error: Core service not configured"}
        else
          case create_task(core_service_url, user_id, project_id, name) do
            {:ok, task_id} ->
              {:ok, "Created task ##{task_id}: #{name}"}

            {:error, reason} ->
              {:ok, "Error creating task: #{inspect(reason)}"}
          end
        end

      _ ->
        {:ok, "Usage: /task {project_id} {name}"}
    end
  end

  defp create_task(base_url, user_id, project_id, name) do
    url = "#{base_url}/api/discord/task"

    body = %{
      "id" => user_id,
      "project_id" => String.to_integer(project_id),
      "name" => name
    }

    case Req.post(url: url, json: body) do
      {:ok, %Req.Response{status: 200, body: %{"id" => task_id}}} ->
        {:ok, task_id}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_assign(_, nil), do: {:ok, "Error: Unable to identify user"}

  defp handle_assign(rest, user_id) do
    # Expect: {task_id} @user
    case String.split(rest, ~r/\s+/, parts: 2) do
      [task_id, user_str] when task_id != "" and user_str != "" ->
        # Extract Discord user ID from mention format
        discord_user_id =
          user_str
          |> String.trim()
          |> String.trim_leading("@")
          |> String.trim_leading("<@")
          |> String.trim_trailing(">")

        if discord_user_id == "" do
          {:ok, "Usage: /assign {task_id} @user"}
        else
          core_service_url = Application.get_env(:comms, :core_service_url)

          if is_nil(core_service_url) or core_service_url == "" do
            {:ok, "Error: Core service not configured"}
          else
            case assign_task(core_service_url, user_id, task_id, discord_user_id) do
              {:ok, result} ->
                assignee_name = get_in(result, ["assignee", "name"]) || "User"

                Task.start(fn ->
                  Comms.Notifications.send_task_assignment_notification(%{
                    "task" => result["task"],
                    "assignee" => result["assignee"],
                    "assigner" => result["assigner"]
                  })
                end)

                {:ok, "Assigned task ##{task_id} to #{assignee_name}"}

              {:error, reason} ->
                {:ok, "Error assigning task: #{inspect(reason)}"}
            end
          end
        end

      _ ->
        {:ok, "Usage: /assign {task_id} @user"}
    end
  end

  defp assign_task(base_url, user_id, task_id, discord_user_id) do
    url = "#{base_url}/api/discord/assign"

    body = %{
      "id" => user_id,
      "task_id" => String.to_integer(task_id),
      "user_id" => discord_user_id
    }

    case Req.post(url: url, json: body) do
      {:ok, %Req.Response{status: 200, body: result}} ->
        {:ok, result}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
