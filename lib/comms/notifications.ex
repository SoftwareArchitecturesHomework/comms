defmodule Comms.Notifications do
  @moduledoc """
  Business logic for building and delivering notification emails.

  Each public function corresponds to a CommsService RPC (HTTP mapped).
  Expects maps shaped like the proto messages converted from JSON payloads.
  """

  require Logger
  alias Comms.Mailer
  alias Swoosh.Email

  defp from_email, do: Application.get_env(:comms, :smtp_from_email)
  defp application_url, do: Application.get_env(:comms, :core_service_public_url)
  defp layout_path, do: Application.get_env(:comms, :email_layout_path)
  defp templates_path, do: Application.get_env(:comms, :email_templates_path)

  # Public API ---------------------------------------------------------------
  def send_user_added_to_project_notification(%{
        "project" => project,
        "manager" => manager,
        "member" => member
      }) do
    assigns = %{
      view_template: "user_added_to_project.html.eex",
      title: "Added to Project",
      project: normalize_project(project),
      manager: normalize_user(manager),
      member: normalize_user(member),
      action_url: application_url() <> "/projects/#{project["id"]}"
    }

    deliver_single(assigns.member.email,
      subject: "You were added to #{assigns.project.name}",
      assigns: assigns
    )

    {:ok, %{sent: 1}}
  end

  def send_user_removed_from_project_notification(%{
        "project" => project,
        "manager" => manager,
        "member" => member
      }) do
    assigns = %{
      view_template: "user_removed_from_project.html.eex",
      title: "Removed from Project",
      project: normalize_project(project),
      manager: normalize_user(manager),
      member: normalize_user(member)
    }

    deliver_single(assigns.member.email,
      subject: "You were removed from #{assigns.project.name}",
      assigns: assigns
    )

    {:ok, %{sent: 1}}
  end

  def send_project_completion_notification(
        %{
          "project" => project,
          "manager" => manager,
          "members" => members
        } = body
      ) do
    normalized_members =
      Enum.map(members, &normalize_user/1)

    assigns_base = %{
      view_template: "project_completion.html.eex",
      title: "Project Completed",
      project: normalize_project(project),
      manager: normalize_user(manager),
      summary: Map.get(body, "summary"),
      action_url: application_url() <> "/projects/#{project["id"]}"
    }

    Enum.each(normalized_members, fn member ->
      assigns = Map.put(assigns_base, :member, member)

      deliver_single(member.email,
        subject: "Project Completed: #{assigns.project.name}",
        assigns: assigns
      )
    end)

    {:ok, %{sent: length(normalized_members)}}
  end

  def send_task_assignment_notification(%{
        "task" => task,
        "assigner" => assigner,
        "assignee" => assignee
      }) do
    assigns = %{
      view_template: "task_assignment.html.eex",
      title: "Task Assignment",
      task: normalize_task(task),
      assigner: normalize_user(assigner),
      assignee: normalize_user(assignee),
      action_url: application_url() <> "/tasks/#{task["id"]}"
    }

    deliver_single(assigns.assignee.email,
      subject: "Assigned: #{assigns.task.name}",
      assigns: assigns
    )

    {:ok, %{sent: 1}}
  end

  def send_task_completion_notification(%{
        "task" => task,
        "assignee" => assignee
      }) do
    assigns = %{
      view_template: "task_completion.html.eex",
      title: "Task Completed",
      task: normalize_task_completion(task),
      assignee: normalize_user(assignee),
      action_url: application_url() <> "/tasks/#{task["id"]}"
    }

    deliver_single(assigns.assignee.email,
      subject: "Completed: #{assigns.task.name}",
      assigns: assigns
    )

    {:ok, %{sent: 1}}
  end

  def send_vacation_request_notification(%{
        "task" => task,
        "assigner" => assigner,
        "assignee" => assignee
      }) do
    assigns = %{
      view_template: "vacation_request.html.eex",
      title: "Vacation Request",
      task: normalize_vacation_task(task),
      assigner: normalize_user(assigner),
      assignee: normalize_user(assignee),
      approve_url: application_url() <> "/approvals/?action=approve:#{task["id"]}",
      deny_url: application_url() <> "/approvals/?action=reject:#{task["id"]}",
      action_url: application_url() <> "/tasks/#{task["id"]}"
    }

    deliver_single(assigns.assignee.email,
      subject: "Permission requested: Vacation from #{assigns.task.start} to #{assigns.task.end}",
      assigns: assigns
    )

    {:ok, %{sent: 1}}
  end

  # Helpers ------------------------------------------------------------------
  defp deliver_single(to_email, subject: subject, assigns: assigns) do
    html = render_with_layout(assigns.view_template, assigns)

    email =
      Email.new()
      |> Email.to(to_email)
      |> Email.from({"WorkPlanner", from_email()})
      |> Email.subject(subject)
      |> Email.html_body(html)
      |> attach_logo()

    case Mailer.deliver(email) do
      {:ok, response} ->
        Logger.info(
          "Email delivered: to=#{to_email} subject=\"#{subject}\" response=#{inspect(response)}"
        )

        {:ok, response}

      {:error, reason} ->
        Logger.error(
          "Email delivery failed: to=#{to_email} subject=\"#{subject}\" error=#{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp attach_logo(email) do
    path = Application.app_dir(:comms, "priv/static/images/logo.png")

    if File.exists?(path) do
      attachment =
        Swoosh.Attachment.new(path,
          filename: "logo.png",
          cid: "logo",
          content_type: "image/png",
          type: :inline
        )

      Email.attachment(email, attachment)
    else
      email
    end
  end

  defp render_with_layout(template, assigns) do
    template_path = Path.join(templates_path(), template)
    inner = EEx.eval_file(template_path, [assigns: assigns], trim: true)
    layout_assigns = Map.merge(assigns, %{inner_content: inner})
    EEx.eval_file(layout_path(), [assigns: layout_assigns], trim: true)
  end

  defp normalize_user(%{"name" => name, "email" => email}), do: %{name: name, email: email}
  defp normalize_project(%{"id" => id, "name" => name}), do: %{id: id, name: name}

  defp normalize_task_completion(%{"id" => id, "name" => name} = map) do
    description = Map.get(map, "description")
    %{id: id, name: name, description: description}
  end

  defp normalize_task(%{"id" => id, "name" => name} = map) do
    endDate = Map.get(map, "end")
    start = Map.get(map, "start")
    description = Map.get(map, "description")
    %{id: id, name: name, start: start, end: endDate, description: description}
  end

  defp normalize_vacation_task(%{
         "id" => id,
         "start" => start,
         "end" => endDate
       }) do
    %{id: id, start: start, end: endDate}
  end
end
