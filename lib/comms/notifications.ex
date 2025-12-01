defmodule Comms.Notifications do
  @moduledoc """
  Business logic for building and delivering notification emails.

  Each public function corresponds to a CommsService RPC (HTTP mapped).
  Expects maps shaped like the proto messages converted from JSON payloads.
  """

  alias Comms.Mailer
  alias Swoosh.Email

  defp from_email, do: Application.get_env(:comms, :smtp_from_email, "noreply@example.com")
  defp application_url, do: Application.get_env(:comms, :core_service_url)

  defp layout_path do
    Path.join([File.cwd!(), Application.get_env(:comms, :email_layout_path)])
  end

  defp templates_path do
    Path.join([File.cwd!(), Application.get_env(:comms, :email_templates_path)])
  end

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
          "member" => member
        } = body
      ) do
    assigns = %{
      view_template: "project_completion.html.eex",
      title: "Project Completed",
      project: normalize_project(project),
      manager: normalize_user(manager),
      member: normalize_user(member),
      summary: Map.get(body, "summary"),
      action_url: application_url() <> "/projects/#{project["id"]}"
    }

    deliver_single(assigns.member.email,
      subject: "#{assigns.project.name} completed",
      assigns: assigns
    )

    {:ok, %{sent: 1}}
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
        "assigner" => assigner,
        "assignee" => assignees
      }) do
    assigns = %{
      task: normalize_task(task),
      assigner: normalize_user(assigner),
      assignees: Enum.map(assignees, &normalize_user/1),
      title: "Task Completed",
      view_template: "task_completion.html.eex"
    }

    recipients = [assigns.assigner.email | Enum.map(assigns.assignees, & &1.email)] |> Enum.uniq()

    Enum.each(recipients, fn email ->
      deliver_single(email, subject: "Completed: #{assigns.task.details.name}", assigns: assigns)
    end)

    {:ok, %{sent: length(recipients)}}
  end

  def send_task_permission_request_notification(%{
        "task" => task,
        "assigner" => assigner,
        "assignee" => assignees
      }) do
    assigns_base = %{
      task: normalize_task(task),
      assigner: normalize_user(assigner),
      assignees: Enum.map(assignees, &normalize_user/1),
      title: "Task Permission Request",
      view_template: "task_permission_request.html.eex"
    }

    Enum.each(assigns_base.assignees, fn user ->
      assigns = Map.put(assigns_base, :recipient, user)

      deliver_single(user.email,
        subject: "Permission requested: #{assigns_base.task.details.name}",
        assigns: assigns
      )
    end)

    {:ok, %{sent: length(assigns_base.assignees)}}
  end

  # Helpers ------------------------------------------------------------------
  defp deliver_single(to_email, subject: subject, assigns: assigns) do
    html = render_with_layout(assigns.view_template, assigns)

    email =
      Email.new()
      |> Email.to(to_email)
      |> Email.from({"Comms", from_email()})
      |> Email.subject(subject)
      |> Email.html_body(html)
      |> attach_logo()

    Mailer.deliver(email)
  end

  defp attach_logo(email) do
    path = Path.join([File.cwd!(), "priv/static/images/logo.png"]) |> Path.expand()

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

  defp normalize_user(%{"name" => name, "email" => email}) do
    %{name: name, email: email}
  end

  defp normalize_project(%{"id" => id, "name" => name}), do: %{id: id, name: name}

  defp normalize_task(%{"id" => id, "name" => name, "start" => start} = map) do
    endDate = Map.get(map, "end")
    description = Map.get(map, "description")
    %{id: id, name: name, start: start, end: endDate, description: description}
  end
end
