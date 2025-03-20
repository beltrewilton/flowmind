defmodule Flowmind.Repo do
  use Ecto.Repo,
    otp_app: :flowmind,
    adapter: Ecto.Adapters.Postgres
end
