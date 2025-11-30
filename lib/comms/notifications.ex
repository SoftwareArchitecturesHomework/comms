defmodule Comms.Notifications do
  @moduledoc """
  Business logic for building and delivering notification emails.

  Each public function corresponds to a CommsService RPC (HTTP mapped).
  Expects maps shaped like the proto messages converted from JSON payloads.
  """

  alias Comms.Mailer
  alias Swoosh.Email

  # existing layout
  @layout_path Path.join([File.cwd!(), "lib/comms_web/templates/email/layout.html.eex"])
  @templates_path Path.join([File.cwd!(), "lib/comms_web/templates/email"])

  # Public API ---------------------------------------------------------------
  def send_user_added_to_project_notification(%{
        "project" => project,
        "manager" => manager,
        "member" => member
      }) do
    assigns = %{
      project: normalize_project(project),
      manager: normalize_user(manager),
      member: normalize_user(member),
      title: "Added to Project",
      view_template: "user_added_to_project.html.eex"
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
      project: normalize_project(project),
      manager: normalize_user(manager),
      member: normalize_user(member),
      title: "Removed from Project",
      view_template: "user_removed_from_project.html.eex"
    }

    deliver_single(assigns.member.email,
      subject: "You were removed from #{assigns.project.name}",
      assigns: assigns
    )

    {:ok, %{sent: 1}}
  end

  def send_project_completion_notification(
        %{"project" => project, "manager" => manager, "member" => member} = payload
      ) do
    assigns = %{
      base_url: application_url(),
      project: normalize_project(project),
      manager: normalize_user(manager),
      member: normalize_user(member),
      summary: Map.get(payload, "summary"),
      action_url: "/projects/#{project["id"]}",
      title: "Project Completed",
      view_template: "project_completion.html.eex"
    }

    IO.inspect(assigns)

    deliver_single(assigns.member.email,
      subject: "#{assigns.project.name} completed",
      assigns: assigns
    )

    {:ok, %{sent: 1}}
  end

  def send_task_assignment_notification(
        %{"task" => task, "assigner" => assigner, "assignee" => assignees} = _payload
      ) do
    assigns_base = %{
      task: normalize_task(task),
      assigner: normalize_user(assigner),
      assignees: Enum.map(assignees, &normalize_user/1),
      title: "Task Assignment",
      view_template: "task_assignment.html.eex"
    }

    Enum.each(assigns_base.assignees, fn user ->
      assigns = Map.put(assigns_base, :recipient, user)

      deliver_single(user.email,
        subject: "Assigned: #{assigns_base.task.details.name}",
        assigns: assigns
      )
    end)

    {:ok, %{sent: length(assigns_base.assignees)}}
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

    Mailer.deliver(email)
  end

  defp render_with_layout(template, assigns) do
    template_path = Path.join(@templates_path, template)
    inner = EEx.eval_file(template_path, [assigns: assigns], trim: true)
    layout_assigns = Map.merge(assigns, %{inner_content: inner})
    EEx.eval_file(@layout_path, [assigns: layout_assigns], trim: true)
  end

  defp from_email, do: System.get_env("SMTP_USERNAME") || "noreply@example.com"

  defp normalize_user(%{"id" => id, "name" => name, "email" => email}) do
    %{id: id, name: name, email: email}
  end

  defp normalize_user(map), do: map

  defp normalize_project(%{"id" => id, "name" => name}), do: %{id: id, name: name}
  defp normalize_project(map), do: map

  defp normalize_task(%{"id" => id, "details" => details}) do
    %{id: id, details: normalize_task_details(details)}
  end

  defp normalize_task(map), do: map

  defp normalize_task_details(%{
         "start" => start,
         "end" => end_time,
         "name" => name,
         "description" => desc
       }) do
    %{start: start, end: end_time, name: name, description: desc}
  end

  defp normalize_task_details(map), do: map

  defp application_url(), do: System.get_env("CORE_SERVICE_HTTP")
end
