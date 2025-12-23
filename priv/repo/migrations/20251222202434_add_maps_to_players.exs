defmodule ArkNovaCoop.Repo.Migrations.AddMapsToPlayers do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :map1, :integer
      add :map2, :integer
    end
  end
end
