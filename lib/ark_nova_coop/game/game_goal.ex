defmodule ArkNovaCoop.Game.GameGoal do
  @moduledoc """
  Schema representing the assignment of a goal to a specific game.

  Tracks which players have claimed completion of each goal in a game.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @typedoc "A game goal assignment"
  @type t :: %__MODULE__{
          id: integer(),
          claimed_by: [String.t()],
          game_id: binary(),
          goal_id: integer(),
          game: Ecto.Association.NotLoaded.t() | ArkNovaCoop.Game.Game.t(),
          goal: Ecto.Association.NotLoaded.t() | ArkNovaCoop.Game.Goal.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "game_goals" do
    field :claimed_by, {:array, :string}, default: []

    belongs_to :game, ArkNovaCoop.Game.Game, type: :binary_id
    belongs_to :goal, ArkNovaCoop.Game.Goal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game_goal, attrs) do
    game_goal
    |> cast(attrs, [:claimed_by, :game_id, :goal_id])
    |> validate_required([:game_id, :goal_id])
  end
end
