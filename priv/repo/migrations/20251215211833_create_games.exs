defmodule ArkNovaCoop.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :player_count, :integer
      add :total_rounds, :integer
      add :current_round, :integer
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
