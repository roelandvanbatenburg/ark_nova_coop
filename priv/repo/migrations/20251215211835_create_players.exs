defmodule ArkNovaCoop.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string
      add :color, :string
      add :game_id, references(:games, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:players, [:game_id])
    create unique_index(:players, [:game_id, :color])
  end
end
