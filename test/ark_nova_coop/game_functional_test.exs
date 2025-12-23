defmodule ArkNovaCoop.GameFunctionalTest do
  use ArkNovaCoop.DataCase

  alias ArkNovaCoop.Game

  setup do
    # Seed the database with goals for testing
    goals = [
      "Build 5+ different enclosures",
      "Have at least 10 animals in your zoo",
      "Complete 3 conservation projects",
      "Reach appeal level 15",
      "Have animals from 4 different continents",
      "Build 2 special enclosures",
      "Have 5 birds in your zoo",
      "Reach conservation level 10",
      "Build a restaurant and a pavilion",
      "Have 3 predators in your zoo",
      "Complete 2 universities",
      "Have 8 different animal types",
      "Build 3 kiosks",
      "Reach appeal level 20",
      "Have animals with size 5 icons"
    ]

    Enum.each(goals, fn description ->
      Game.create_goal(%{description: description})
    end)

    :ok
  end

  describe "1 player game - standard difficulty" do
    test "win scenario: player achieves all goals and conservation >= appeal" do
      # Setup: Create game with standard difficulty (6 rounds)
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      # Add 1 player
      {:ok, _player} =
        Game.create_player(%{
          game_id: game.id,
          name: "Alice",
          color: "yellow"
        })

      # Start the game
      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      # Verify game setup
      assert game.status == "playing"
      assert game.player_count == 1
      assert game.total_rounds == 6
      assert game.current_round == 1
      # 4 + 1 player
      assert length(game.game_goals) == 5

      # Verify maps are assigned
      players = Game.list_players(game.id)
      player = Enum.find(players, &(&1.color == "yellow"))
      assert player.map1 != nil
      assert player.map2 != nil
      assert player.map1 < player.map2

      # Player claims 4 goals (required: 4 * 1 = 4)
      game.game_goals
      |> Enum.take(4)
      |> Enum.each(fn game_goal ->
        Game.toggle_goal_claim(game_goal.id, "yellow")
      end)

      # Mark player's conservation as met
      Game.toggle_player_conservation(player.id)

      # Advance through rounds and finish game
      game = Game.get_game!(game.id)
      {:ok, game} = Game.next_round(game)
      {:ok, game} = Game.next_round(game)
      {:ok, game} = Game.finish_game(game)

      # Verify win conditions
      game = Game.get_game!(game.id)
      assert game.status == "finished"
      assert Game.goal_condition_met?(game) == true
      assert Game.total_goal_claims(game) >= Game.required_goals_count(game)
      assert Game.all_players_conservation_met?(game.id) == true
    end

    test "loss scenario: player doesn't achieve enough goals" do
      # Setup
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      {:ok, player} =
        Game.create_player(%{
          game_id: game.id,
          name: "Bob",
          color: "red"
        })

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      # Player claims only 2 goals (needs 4)
      game.game_goals
      |> Enum.take(2)
      |> Enum.each(fn game_goal ->
        Game.toggle_goal_claim(game_goal.id, "red")
      end)

      # Mark conservation as met
      Game.toggle_player_conservation(player.id)

      # Finish game
      {:ok, game} = Game.finish_game(game)

      # Verify loss condition
      game = Game.get_game!(game.id)
      assert game.status == "finished"
      assert Game.goal_condition_met?(game) == false
      assert Game.total_goal_claims(game) < Game.required_goals_count(game)
      assert Game.all_players_conservation_met?(game.id) == true
    end

    test "loss scenario: conservation not met" do
      # Setup
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      {:ok, _player} =
        Game.create_player(%{
          game_id: game.id,
          name: "Charlie",
          color: "blue"
        })

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      # Player claims all 5 goals
      game.game_goals
      |> Enum.each(fn game_goal ->
        Game.toggle_goal_claim(game_goal.id, "blue")
      end)

      # Don't mark conservation as met

      # Finish game
      {:ok, game} = Game.finish_game(game)

      # Verify loss condition
      game = Game.get_game!(game.id)
      assert game.status == "finished"
      assert Game.goal_condition_met?(game) == true
      assert Game.all_players_conservation_met?(game.id) == false
    end
  end

  describe "1 player game - hard difficulty" do
    test "win scenario with 5 rounds" do
      # Setup: Create game with hard difficulty (5 rounds)
      {:ok, game} = Game.create_game(%{total_rounds: 5, status: "setup"})

      {:ok, player} =
        Game.create_player(%{
          game_id: game.id,
          name: "Diana",
          color: "black"
        })

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      # Verify hard mode setup
      assert game.total_rounds == 5

      # Player claims 4 goals
      game.game_goals
      |> Enum.take(4)
      |> Enum.each(fn game_goal ->
        Game.toggle_goal_claim(game_goal.id, "black")
      end)

      # Mark conservation as met
      Game.toggle_player_conservation(player.id)

      # Finish game
      {:ok, game} = Game.finish_game(game)

      # Verify win
      game = Game.get_game!(game.id)
      assert game.status == "finished"
      assert Game.goal_condition_met?(game) == true
      assert Game.all_players_conservation_met?(game.id) == true
    end
  end

  describe "4 player game - standard difficulty" do
    test "win scenario: all players achieve goals and conservation" do
      # Setup
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      # Add 4 players
      colors = ["yellow", "red", "blue", "black"]

      players_data = [
        %{name: "Alice", color: "yellow"},
        %{name: "Bob", color: "red"},
        %{name: "Charlie", color: "blue"},
        %{name: "Diana", color: "black"}
      ]

      Enum.each(players_data, fn player_data ->
        {:ok, _player} = Game.create_player(Map.put(player_data, :game_id, game.id))
      end)

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      # Verify game setup
      assert game.player_count == 4
      # 4 + 4 players
      assert length(game.game_goals) == 8

      # Verify all 4 players have maps assigned
      players = Game.list_players(game.id)
      assert length(players) == 4

      Enum.each(players, fn player ->
        assert player.map1 != nil
        assert player.map2 != nil
        assert player.map1 < player.map2
      end)

      # Verify map constraints: maps 1-8 unique, 9-10 max 2 total
      all_maps =
        Enum.flat_map(players, fn player -> [player.map1, player.map2] end)

      # Count occurrences of each map
      map_counts = Enum.frequencies(all_maps)

      # Maps 1-8 should appear at most once
      Enum.each(1..8, fn map_num ->
        assert Map.get(map_counts, map_num, 0) <= 1
      end)

      # Maps 9 and 10 combined should appear at most 2 times
      nine_ten_count = Map.get(map_counts, 9, 0) + Map.get(map_counts, 10, 0)
      assert nine_ten_count <= 2

      # Each player claims 4 goals (total 16 claims, required: 4 * 4 = 16)
      game.game_goals
      |> Enum.each(fn game_goal ->
        Enum.each(colors, fn color ->
          Game.toggle_goal_claim(game_goal.id, color)
        end)
      end)

      # Mark all players' conservation as met
      Enum.each(players, fn player ->
        Game.toggle_player_conservation(player.id)
      end)

      # Finish game
      {:ok, game} = Game.finish_game(game)

      # Verify win
      game = Game.get_game!(game.id)
      assert game.status == "finished"
      # 8 goals * 4 players
      assert Game.total_goal_claims(game) == 32
      assert Game.required_goals_count(game) == 16
      assert Game.goal_condition_met?(game) == true
      assert Game.all_players_conservation_met?(game.id) == true
    end

    test "loss scenario: not enough goals claimed" do
      # Setup
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      players_data = [
        %{name: "Alice", color: "yellow"},
        %{name: "Bob", color: "red"},
        %{name: "Charlie", color: "blue"},
        %{name: "Diana", color: "black"}
      ]

      players =
        Enum.map(players_data, fn player_data ->
          {:ok, player} = Game.create_player(Map.put(player_data, :game_id, game.id))
          player
        end)

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      # Only 2 players claim 3 goals each (6 total, needs 16)
      game.game_goals
      |> Enum.take(3)
      |> Enum.each(fn game_goal ->
        Game.toggle_goal_claim(game_goal.id, "yellow")
        Game.toggle_goal_claim(game_goal.id, "red")
      end)

      # Mark all players' conservation as met
      Enum.each(players, fn player ->
        Game.toggle_player_conservation(player.id)
      end)

      # Finish game
      {:ok, game} = Game.finish_game(game)

      # Verify loss
      game = Game.get_game!(game.id)
      assert game.status == "finished"
      assert Game.total_goal_claims(game) == 6
      assert Game.required_goals_count(game) == 16
      assert Game.goal_condition_met?(game) == false
      assert Game.all_players_conservation_met?(game.id) == true
    end

    test "loss scenario: one player missing conservation" do
      # Setup
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      players_data = [
        %{name: "Alice", color: "yellow"},
        %{name: "Bob", color: "red"},
        %{name: "Charlie", color: "blue"},
        %{name: "Diana", color: "black"}
      ]

      players =
        Enum.map(players_data, fn player_data ->
          {:ok, player} = Game.create_player(Map.put(player_data, :game_id, game.id))
          player
        end)

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      # All players claim 4 goals each
      game.game_goals
      |> Enum.each(fn game_goal ->
        Enum.each(["yellow", "red", "blue", "black"], fn color ->
          Game.toggle_goal_claim(game_goal.id, color)
        end)
      end)

      # Mark only 3 players' conservation as met
      players
      |> Enum.take(3)
      |> Enum.each(fn player ->
        Game.toggle_player_conservation(player.id)
      end)

      # Finish game
      {:ok, game} = Game.finish_game(game)

      # Verify loss
      game = Game.get_game!(game.id)
      assert game.status == "finished"
      assert Game.goal_condition_met?(game) == true
      assert Game.all_players_conservation_met?(game.id) == false
    end
  end

  describe "4 player game - hard difficulty" do
    test "win scenario with 5 rounds" do
      # Setup: Create game with hard difficulty (5 rounds)
      {:ok, game} = Game.create_game(%{total_rounds: 5, status: "setup"})

      players_data = [
        %{name: "Alice", color: "yellow"},
        %{name: "Bob", color: "red"},
        %{name: "Charlie", color: "blue"},
        %{name: "Diana", color: "black"}
      ]

      players =
        Enum.map(players_data, fn player_data ->
          {:ok, player} = Game.create_player(Map.put(player_data, :game_id, game.id))
          player
        end)

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      # Verify hard mode
      assert game.total_rounds == 5

      # Each player claims 4 goals
      game.game_goals
      |> Enum.each(fn game_goal ->
        Enum.each(["yellow", "red", "blue", "black"], fn color ->
          Game.toggle_goal_claim(game_goal.id, color)
        end)
      end)

      # Mark all conservation as met
      Enum.each(players, fn player ->
        Game.toggle_player_conservation(player.id)
      end)

      # Finish game
      {:ok, game} = Game.finish_game(game)

      # Verify win
      game = Game.get_game!(game.id)
      assert game.status == "finished"
      assert game.total_rounds == 5
      assert Game.goal_condition_met?(game) == true
      assert Game.all_players_conservation_met?(game.id) == true
    end
  end

  describe "round progression" do
    test "can advance through rounds until finished" do
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      {:ok, _player} =
        Game.create_player(%{
          game_id: game.id,
          name: "Alice",
          color: "yellow"
        })

      {:ok, game} = Game.start_game(game)

      # Advance through all rounds
      {:ok, game} = Game.next_round(game)
      assert game.current_round == 2

      {:ok, game} = Game.next_round(game)
      assert game.current_round == 3

      {:ok, game} = Game.next_round(game)
      assert game.current_round == 4

      {:ok, game} = Game.next_round(game)
      assert game.current_round == 5

      {:ok, game} = Game.next_round(game)
      assert game.current_round == 6

      # Can't advance past final round
      {:error, :game_finished} = Game.next_round(game)
    end
  end

  describe "goal claiming" do
    test "can toggle goal claims on and off" do
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      {:ok, _player} =
        Game.create_player(%{
          game_id: game.id,
          name: "Alice",
          color: "yellow"
        })

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      game_goal = List.first(game.game_goals)

      # Initially not claimed
      assert game_goal.claimed_by == []

      # Claim the goal
      {:ok, _} = Game.toggle_goal_claim(game_goal.id, "yellow")
      game = Game.get_game!(game.id)
      game_goal = Enum.find(game.game_goals, &(&1.id == game_goal.id))
      assert "yellow" in game_goal.claimed_by

      # Unclaim the goal
      {:ok, _} = Game.toggle_goal_claim(game_goal.id, "yellow")
      game = Game.get_game!(game.id)
      game_goal = Enum.find(game.game_goals, &(&1.id == game_goal.id))
      assert "yellow" not in game_goal.claimed_by
    end

    test "multiple players can claim the same goal" do
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      {:ok, _player1} =
        Game.create_player(%{
          game_id: game.id,
          name: "Alice",
          color: "yellow"
        })

      {:ok, _player2} =
        Game.create_player(%{
          game_id: game.id,
          name: "Bob",
          color: "red"
        })

      {:ok, started_game} = Game.start_game(game)
      game = Game.get_game!(started_game.id)

      game_goal = List.first(game.game_goals)

      # Both players claim the same goal
      {:ok, _} = Game.toggle_goal_claim(game_goal.id, "yellow")
      {:ok, _} = Game.toggle_goal_claim(game_goal.id, "red")

      game = Game.get_game!(game.id)
      game_goal = Enum.find(game.game_goals, &(&1.id == game_goal.id))

      assert "yellow" in game_goal.claimed_by
      assert "red" in game_goal.claimed_by
      assert length(game_goal.claimed_by) == 2
    end
  end
end
