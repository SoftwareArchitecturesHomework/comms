defmodule CommsWeb.Emails.BaseEmail do
    @moduledoc """
    Base module for email templates.

    All email templates should use this module to access common helpers
    and configurations for email rendering.
    """

    import Swoosh.Email

    @from_email "noreply@example.com"
    @from_name "Comms Service"

    def new_email do
        new()
        |> from({@from_name, @from_email})
    end

    def new_email(to_email) when is_binary(to_email) do
        new_email()
        |> to(to_email)
    end

    def new_email(to_email, to_name) when is_binary(to_email) and is_binary(to_name) do
        new_email()
        |> to({to_name, to_email})
    end
end
