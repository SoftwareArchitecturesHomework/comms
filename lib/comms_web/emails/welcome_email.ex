defmodule CommsWeb.Emails.WelcomeEmail do
    @moduledoc """
    Welcome email template.

    Example usage:

        CommsWeb.Emails.WelcomeEmail.build("user@example.com", %{name: "John Doe"})
        |> Comms.Mailer.deliver()
    """

    import Swoosh.Email
    import CommsWeb.Emails.BaseEmail

    def build(to_email, %{name: name} = _params) do
        new_email(to_email, name)
        |> subject("Welcome to our service!")
        |> html_body(html_content(name))
        |> text_body(text_content(name))
    end

    defp html_content(name) do
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
            body {
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 600px;
                margin: 0 auto;
                padding: 20px;
            }
            .header {
                background-color: #4F46E5;
                color: white;
                padding: 20px;
                text-align: center;
                border-radius: 5px 5px 0 0;
            }
            .content {
                background-color: #f9fafb;
                padding: 30px;
                border-radius: 0 0 5px 5px;
            }
            .button {
                display: inline-block;
                background-color: #4F46E5;
                color: white;
                padding: 12px 24px;
                text-decoration: none;
                border-radius: 5px;
                margin-top: 20px;
            }
            </style>
        </head>
        <body>
            <div class="header">
            <h1>Welcome!</h1>
            </div>
            <div class="content">
            <p>Hello #{name},</p>
            <p>Welcome to our service! We're excited to have you on board.</p>
            <p>If you have any questions, feel free to reach out to our support team.</p>
            <p>Best regards,<br>The Team</p>
            </div>
        </body>
        </html>
        """
    end

    defp text_content(name) do
        """
        Hello #{name},

        Welcome to our service! We're excited to have you on board.

        If you have any questions, feel free to reach out to our support team.

        Best regards,
        The Team
        """
    end
end
