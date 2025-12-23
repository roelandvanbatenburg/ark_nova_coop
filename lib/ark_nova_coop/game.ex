defmodule ArkNovaCoop.Game do
  @moduledoc """
  The Game context for managing Ark Nova cooperative games.
  """

  import Ecto.Query, warn: false
  alias ArkNovaCoop.Repo

  alias ArkNovaCoop.Game.{Game, Player, Goal, GameGoal}

  @doc """
  Creates a new game with the specified player count.
  """
  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single game by ID.
  """
  def get_game!(id) do
    Repo.get!(Game, id)
    |> Repo.preload([:players, game_goals: :goal])
  end

  @doc """
  Updates a game.
  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Initializes a game with random goals based on player count.
  Goals are drawn as 4 + player_count.
  """
  def initialize_game_goals(%Game{} = game) do
    goal_count = 4 + game.player_count

    random_goals =
      Goal
      |> order_by(fragment("RANDOM()"))
      |> limit(^goal_count)
      |> Repo.all()

    Enum.each(random_goals, fn goal ->
      %GameGoal{}
      |> GameGoal.changeset(%{game_id: game.id, goal_id: goal.id})
      |> Repo.insert!()
    end)

    get_game!(game.id)
  end

  @doc """
  Creates a player for a game.
  """
  def create_player(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists all players for a game.
  """
  def list_players(game_id) do
    Player
    |> where([p], p.game_id == ^game_id)
    |> Repo.all()
  end

  @doc """
  Toggles the conservation_met status for a player.
  """
  def toggle_player_conservation(player_id) do
    player = Repo.get!(Player, player_id)

    player
    |> Player.changeset(%{conservation_met: !player.conservation_met})
    |> Repo.update()
  end

  @doc """
  Toggles a goal claim for a player.
  If the player has already claimed the goal, removes their claim.
  If they haven't claimed it, adds their claim.
  """
  def toggle_goal_claim(game_goal_id, player_color) do
    game_goal = Repo.get!(GameGoal, game_goal_id)
    claimed_by = game_goal.claimed_by || []

    new_claimed_by =
      if player_color in claimed_by do
        List.delete(claimed_by, player_color)
      else
        [player_color | claimed_by]
      end

    game_goal
    |> GameGoal.changeset(%{claimed_by: new_claimed_by})
    |> Repo.update()
  end

  @doc """
  Checks if a goal is claimed by a specific player.
  """
  def goal_claimed_by?(game_goal, player_color) do
    player_color in (game_goal.claimed_by || [])
  end

  @doc """
  Advances the game to the next round.
  """
  def next_round(%Game{} = game) do
    if game.current_round < game.total_rounds do
      update_game(game, %{current_round: game.current_round + 1})
    else
      {:error, :game_finished}
    end
  end

  @doc """
  Assigns maps to all players in a game.
  Maps 1-8 are unique cards.
  Maps 9 and 10 are two sides of the same card - there are 2 such two-sided cards.
  This means the total count of 9s and 10s combined cannot exceed 2.
  Each player gets 2 maps.
  """
  def assign_maps_to_players(game_id) do
    players = list_players(game_id)

    # Create map pool: 1-8 (unique maps) + 2 two-sided cards (represented as :two_sided)
    map_pool = Enum.to_list(1..8) ++ [:two_sided, :two_sided]

    # Shuffle the pool
    shuffled_pool = Enum.shuffle(map_pool)

    # Assign maps to each player
    {_remaining_pool, _} =
      Enum.reduce(players, {shuffled_pool, 0}, fn player, {pool, _idx} ->
        # Take 2 maps for this player
        [raw_map1, raw_map2 | rest] = pool

        # For two-sided cards, randomly pick side 9 or 10
        map1_raw = if raw_map1 == :two_sided, do: Enum.random([9, 10]), else: raw_map1
        map2_raw = if raw_map2 == :two_sided, do: Enum.random([9, 10]), else: raw_map2

        # Sort maps so map1 is always the lower number
        [map1, map2] = Enum.sort([map1_raw, map2_raw])

        # Update player with their maps
        player
        |> Player.changeset(%{map1: map1, map2: map2})
        |> Repo.update!()

        {rest, 0}
      end)

    :ok
  end

  @doc """
  Starts the game by setting player count based on registered players,
  selecting a random starting player, initializing goals, assigning maps, and changing status to "playing".
  """
  def start_game(%Game{} = game) do
    players = list_players(game.id)
    player_count = length(players)

    if player_count > 0 do
      # Select random starting player
      starting_player = Enum.random(players).color

      # Update game with player count and starting player
      {:ok, game} =
        update_game(game, %{
          player_count: player_count,
          starting_player: starting_player,
          status: "playing"
        })

      # Initialize goals
      game = initialize_game_goals(game)

      # Assign maps to players
      assign_maps_to_players(game.id)

      {:ok, game}
    else
      {:error, :no_players}
    end
  end

  @doc """
  Ends the game (changes status to "finished").
  """
  def finish_game(%Game{} = game) do
    update_game(game, %{status: "finished"})
  end

  @doc """
  Lists all goals.
  """
  def list_goals do
    Repo.all(Goal)
  end

  @doc """
  Creates a goal.
  """
  def create_goal(attrs \\ %{}) do
    %Goal{}
    |> Goal.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets available player colors for a game (colors not yet taken).
  """
  def available_colors(game_id) do
    taken_colors =
      Player
      |> where([p], p.game_id == ^game_id)
      |> select([p], p.color)
      |> Repo.all()

    ["yellow", "red", "blue", "black"] -- taken_colors
  end

  @doc """
  Checks if the goal count win condition is met.
  Players win if total goal claims >= 4 * player_count.
  Each player's claim counts individually (multiple players can claim the same goal).
  """
  def goal_condition_met?(%Game{} = game) do
    claimed_count = total_goal_claims(game)
    required_count = 4 * game.player_count
    claimed_count >= required_count
  end

  @doc """
  Gets the required number of goal claims to win (4 × player count).
  """
  def required_goals_count(%Game{} = game) do
    4 * game.player_count
  end

  @doc """
  Gets the total count of goal claims across all players.
  Each player's claim on a goal counts separately.
  """
  def total_goal_claims(%Game{} = game) do
    Enum.reduce(game.game_goals, 0, fn gg, acc ->
      acc + length(gg.claimed_by || [])
    end)
  end

  @doc """
  Checks if all players have met the conservation condition.
  Returns true if all players have conservation_met set to true.
  """
  def all_players_conservation_met?(game_id) do
    players = list_players(game_id)
    Enum.all?(players, fn player -> player.conservation_met end)
  end
end
