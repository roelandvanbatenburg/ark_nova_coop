defmodule ArkNovaCoop.Repo.Migrations.UpdateGameGoalForMultipleClaims do
  use Ecto.Migration

  def up do
    # Add starting_player to games
    alter table(:games) do
      add :starting_player, :string
    end

    # For SQLite: recreate the table with the new column type
    # For PostgreSQL: use ALTER COLUMN
    if repo().__adapter__() == Ecto.Adapters.SQLite3 do
      # SQLite: Drop and recreate the column
      # Since SQLite doesn't support ALTER COLUMN, we need to use TEXT to store JSON arrays
      # The Ecto schema will handle serialization/deserialization
      alter table(:game_goals) do
        remove :claimed_by
      end

      alter table(:game_goals) do
        add :claimed_by, :text
      end
    else
      # PostgreSQL: Change claimed_by from string to array of strings
      execute """
      ALTER TABLE game_goals
      ALTER COLUMN claimed_by TYPE text[]
      USING CASE
        WHEN claimed_by IS NULL THEN ARRAY[]::text[]
        ELSE ARRAY[claimed_by]::text[]
      END
      """
    end
  end

  def down do
    # Remove starting_player from games
    alter table(:games) do
      remove :starting_player
    end

    if repo().__adapter__() == Ecto.Adapters.SQLite3 do
      alter table(:game_goals) do
        remove :claimed_by
      end

      alter table(:game_goals) do
        add :claimed_by, :string
      end
    else
      # Change claimed_by back to string
      execute """
      ALTER TABLE game_goals
      ALTER COLUMN claimed_by TYPE text
      USING CASE
        WHEN array_length(claimed_by, 1) > 0 THEN claimed_by[1]
        ELSE NULL
      END
      """
    end
  end
end
