defmodule Comms.Repo do
  use Ecto.Repo,
    otp_app: :comms,
    adapter: Ecto.Adapters.Postgres
end
