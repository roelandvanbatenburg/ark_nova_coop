defmodule ArkNovaCoop.Game.Game do
  @moduledoc """
  Schema for cooperative Ark Nova games.

  Tracks the overall game state including rounds, players, goals, and game status.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @typedoc "A cooperative game"
  @type t :: %__MODULE__{
          id: binary(),
          status: String.t(),
          player_count: integer() | nil,
          total_rounds: integer(),
          current_round: integer(),
          starting_player: String.t() | nil,
          players: Ecto.Association.NotLoaded.t() | [ArkNovaCoop.Game.Player.t()],
          game_goals: Ecto.Association.NotLoaded.t() | [ArkNovaCoop.Game.GameGoal.t()],
          goals: Ecto.Association.NotLoaded.t() | [ArkNovaCoop.Game.Goal.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "games" do
    field :status, :string, default: "setup"
    field :player_count, :integer
    field :total_rounds, :integer
    field :current_round, :integer, default: 1
    field :starting_player, :string

    has_many :players, ArkNovaCoop.Game.Player
    has_many :game_goals, ArkNovaCoop.Game.GameGoal
    has_many :goals, through: [:game_goals, :goal]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:player_count, :total_rounds, :current_round, :status, :starting_player])
    |> validate_required([:total_rounds])
    |> validate_inclusion(:player_count, 1..4)
    |> validate_inclusion(:total_rounds, [5, 6])
  end
end
