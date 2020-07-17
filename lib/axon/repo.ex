defmodule Axon.Repo do
  use Ecto.Repo,
    otp_app: :axon,
    adapter: Ecto.Adapters.Postgres
end
