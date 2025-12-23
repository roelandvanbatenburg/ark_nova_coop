defmodule ArkNovaCoop.Repo.Migrations.CreateGameGoals do
  use Ecto.Migration

  def change do
    create table(:game_goals) do
      add :claimed_by, :string
      add :game_id, references(:games, on_delete: :delete_all)
      add :goal_id, references(:goals, on_delete: :restrict)

      timestamps(type: :utc_datetime)
    end

    create index(:game_goals, [:game_id])
    create index(:game_goals, [:goal_id])
    create unique_index(:game_goals, [:game_id, :goal_id])
  end
end
