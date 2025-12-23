defmodule ArkNovaCoop.Repo.Migrations.CreateGoals do
  use Ecto.Migration

  def change do
    create table(:goals) do
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:goals, [:description])
  end
end
