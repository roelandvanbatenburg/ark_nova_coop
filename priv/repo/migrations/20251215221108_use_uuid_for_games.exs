defmodule ArkNovaCoop.Repo.Migrations.UseUuidForGames do
  use Ecto.Migration

  def up do
    # Drop foreign key constraints (PostgreSQL only - SQLite handles this automatically)
    unless repo().__adapter__() == Ecto.Adapters.SQLite3 do
      drop constraint(:players, "players_game_id_fkey")
      drop constraint(:game_goals, "game_goals_game_id_fkey")
    end

    # Drop indexes that reference game_id
    drop unique_index(:players, [:game_id, :color])
    drop index(:players, [:game_id])
    drop unique_index(:game_goals, [:game_id, :goal_id])
    drop index(:game_goals, [:game_id])

    # Drop game_id columns
    alter table(:players) do
      remove :game_id
    end

    alter table(:game_goals) do
      remove :game_id
    end

    # Drop games table and recreate with UUID
    drop table(:games)

    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :player_count, :integer
      add :total_rounds, :integer
      add :current_round, :integer
      add :status, :string
      add :starting_player, :string

      timestamps(type: :utc_datetime)
    end

    # Add game_id back to players and game_goals with UUID type
    alter table(:players) do
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all)
    end

    alter table(:game_goals) do
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all)
    end

    # Recreate indexes
    create index(:players, [:game_id])
    create unique_index(:players, [:game_id, :color])
    create index(:game_goals, [:game_id])
    create unique_index(:game_goals, [:game_id, :goal_id])
  end

  def down do
    # Drop foreign key constraints (PostgreSQL only - SQLite handles this automatically)
    unless repo().__adapter__() == Ecto.Adapters.SQLite3 do
      drop constraint(:players, "players_game_id_fkey")
      drop constraint(:game_goals, "game_goals_game_id_fkey")
    end

    # Drop indexes
    drop unique_index(:players, [:game_id, :color])
    drop index(:players, [:game_id])
    drop unique_index(:game_goals, [:game_id, :goal_id])
    drop index(:game_goals, [:game_id])

    # Drop game_id columns
    alter table(:players) do
      remove :game_id
    end

    alter table(:game_goals) do
      remove :game_id
    end

    # Drop games table and recreate with integer ID
    drop table(:games)

    create table(:games) do
      add :player_count, :integer
      add :total_rounds, :integer
      add :current_round, :integer
      add :status, :string
      add :starting_player, :string

      timestamps(type: :utc_datetime)
    end

    # Add game_id back to players and game_goals with integer type
    alter table(:players) do
      add :game_id, references(:games, on_delete: :delete_all)
    end

    alter table(:game_goals) do
      add :game_id, references(:games, on_delete: :delete_all)
    end

    # Recreate indexes
    create index(:players, [:game_id])
    create unique_index(:players, [:game_id, :color])
    create index(:game_goals, [:game_id])
    create unique_index(:game_goals, [:game_id, :goal_id])
  end
end
