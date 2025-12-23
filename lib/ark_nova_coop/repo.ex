defmodule ArkNovaCoop.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :ark_nova_coop,
    adapter: Ecto.Adapters.SQLite3
end
