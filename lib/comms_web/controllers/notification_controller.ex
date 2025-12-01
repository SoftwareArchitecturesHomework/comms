defmodule CommsWeb.NotificationController do
  use CommsWeb, :controller

  alias Comms.Notifications

  # Each action expects JSON body shaped per proto message.

  def user_added(conn, params),
    do: generic(conn, fn -> Notifications.send_user_added_to_project_notification(params) end)

  def user_removed(conn, params),
    do: generic(conn, fn -> Notifications.send_user_removed_from_project_notification(params) end)

  def project_completed(conn, params),
    do: generic(conn, fn -> Notifications.send_project_completion_notification(params) end)

  def task_assigned(conn, params),
    do: generic(conn, fn -> Notifications.send_task_assignment_notification(params) end)

  def task_completed(conn, params),
    do: generic(conn, fn -> Notifications.send_task_completion_notification(params) end)

  def task_permission_request(conn, params),
    do: generic(conn, fn -> Notifications.send_task_permission_request_notification(params) end)

  defp generic(conn, fun) do
    {:ok, meta} = fun.()
    json(conn, %{success: true, meta: meta})
  rescue
    e -> conn |> put_status(:bad_request) |> json(%{success: false, error: Exception.message(e)})
  end
end
