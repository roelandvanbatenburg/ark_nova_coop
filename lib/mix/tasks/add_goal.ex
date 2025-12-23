defmodule Mix.Tasks.AddGoal do
  @moduledoc """
  Adds a new goal to the database.

  ## Examples

      mix add_goal "Build 5+ enclosures"
  """
  use Mix.Task

  alias ArkNovaCoop.Repo
  alias ArkNovaCoop.Game.Goal

  @shortdoc "Adds a new goal to the database"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      [description] when is_binary(description) and byte_size(description) > 0 ->
        add_goal(description)

      _ ->
        IO.puts("Error: Please provide a goal description.")
        IO.puts("Usage: mix add_goal \"Goal description here\"")
    end
  end

  defp add_goal(description) do
    case Repo.insert(%Goal{description: description}) do
      {:ok, goal} ->
        IO.puts("Successfully added goal: #{goal.description}")
        IO.puts("ID: #{goal.id}")

      {:error, changeset} ->
        IO.puts("Error adding goal:")

        Enum.each(changeset.errors, fn {field, {message, _}} ->
          IO.puts("  #{field}: #{message}")
        end)
    end
  end
end
