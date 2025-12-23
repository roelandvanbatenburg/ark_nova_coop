defmodule ArkNovaCoop.Game.Goal do
  @moduledoc """
  Schema for cooperative game goals.

  Goals are shared objectives that players work together to achieve during a game.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @typedoc "A cooperative game goal"
  @type t :: %__MODULE__{
          id: integer(),
          description: String.t(),
          game_goals: Ecto.Association.NotLoaded.t() | [ArkNovaCoop.Game.GameGoal.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "goals" do
    field :description, :string

    has_many :game_goals, ArkNovaCoop.Game.GameGoal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs) do
    goal
    |> cast(attrs, [:description])
    |> validate_required([:description])
    |> unique_constraint(:description)
  end
end
