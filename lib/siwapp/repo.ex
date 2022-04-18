defmodule Siwapp.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :siwapp,
    adapter: Ecto.Adapters.Postgres
end
