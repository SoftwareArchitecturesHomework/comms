defmodule CommsWeb.EmailController do
  use CommsWeb, :controller

  require Logger

  @doc """
  Send an email via POST /api/emails

  Expected params:
  - template: the email template name (e.g., "welcome")
  - to: recipient email address
  - params: template-specific parameters

  Example request:
      POST /api/emails
      {
      "template": "welcome",
      "to": "user@example.com",
      "params": {
          "name": "John Doe"
      }
      }
  """
  def send_email(conn, %{"template" => template, "to" => to, "params" => params}) do
    case build_and_send_email(template, to, params) do
      {:ok, _metadata} ->
        json(conn, %{status: "success", message: "Email sent successfully"})

      {:error, reason} ->
        Logger.error("Failed to send email: #{inspect(reason)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", message: "Failed to send email"})
    end
  end

  def send_email(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{status: "error", message: "Missing required parameters: template, to, params"})
  end

  defp build_and_send_email("welcome", to, params) do
    params_with_atoms = atomize_keys(params)

    CommsWeb.Emails.WelcomeEmail.build(to, params_with_atoms)
    |> Comms.Mailer.deliver()
  end

  defp build_and_send_email(template, _to, _params) do
    {:error, "Unknown template: #{template}"}
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  @doc """
  Send a quick test email to the configured SMTP_USERNAME.

  GET /api/email/test
  """
  def send_test(conn, _params) do
    recipient = System.get_env("SMTP_USERNAME") || ""

    if recipient == "" do
      conn
      |> put_status(:internal_server_error)
      |> json(%{status: "error", message: "SMTP_USERNAME not configured"})
    else
      email =
        Swoosh.Email.new()
        |> Swoosh.Email.to(recipient)
        |> Swoosh.Email.from({"Comms API", recipient})
        |> Swoosh.Email.subject("Comms API Test Email")
        |> Swoosh.Email.html_body(
          "<h1>This is a test email from Comms API</h1><p>If you received this email, the SMTP configuration is working correctly.</p><div style=\"font-size:small;color:gray;\">Sent at #{DateTime.utc_now()}</div>"
        )

      case Comms.Mailer.deliver(email) do
        {:ok, _metadata} ->
          json(conn, %{status: "success", message: "Test email sent"})

        {:error, reason} ->
          Logger.error("Failed to send test email: #{inspect(reason)}")

          # Normalize reason for JSON response
          reason_str =
            case reason do
              {:retries_exceeded, inner} -> "retries_exceeded: #{inspect(inner)}"
              {:smtp_error, code, msg} -> "smtp_error #{code}: #{msg}"
              other -> inspect(other)
            end

          conn
          |> put_status(:internal_server_error)
          |> json(%{status: "error", message: "Failed to send test email", reason: reason_str})
      end
    end
  end
end
