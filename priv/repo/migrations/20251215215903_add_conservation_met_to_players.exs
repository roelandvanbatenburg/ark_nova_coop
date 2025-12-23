defmodule ArkNovaCoop.Repo.Migrations.AddConservationMetToPlayers do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :conservation_met, :boolean, default: false
    end
  end
end
