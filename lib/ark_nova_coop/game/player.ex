defmodule ArkNovaCoop.Game.Player do
  @moduledoc """
  Schema for players in an Ark Nova cooperative game.

  Each player has a name, color, conservation status, and two assigned zoo maps.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @foreign_key_type :binary_id

  @typedoc "A player in a cooperative game"
  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          color: String.t(),
          conservation_met: boolean(),
          map1: integer() | nil,
          map2: integer() | nil,
          game_id: binary(),
          game: Ecto.Association.NotLoaded.t() | ArkNovaCoop.Game.Game.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "players" do
    field :name, :string
    field :color, :string
    field :conservation_met, :boolean, default: false
    field :map1, :integer
    field :map2, :integer

    belongs_to :game, ArkNovaCoop.Game.Game, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :color, :game_id, :conservation_met, :map1, :map2])
    |> validate_required([:name, :color, :game_id])
    |> validate_inclusion(:color, ["yellow", "red", "blue", "black"])
  end
end
