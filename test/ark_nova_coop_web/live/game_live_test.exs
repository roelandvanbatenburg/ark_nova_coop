defmodule ArkNovaCoopWeb.GameLiveTest do
  use ArkNovaCoopWeb.ConnCase

  import Phoenix.LiveViewTest

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

  describe "Home page (GameLive.Index)" do
    test "displays welcome message and create game button", %{conn: conn} do
      {:ok, index_live, html} = live(conn, ~p"/")

      assert html =~ "Ark Nova Cooperative"
      assert html =~ "Track your cooperative zoo-building adventure"
      assert html =~ "Create New Game"
      assert has_element?(index_live, "a[href='/games/new']")
    end

    test "displays cooperative rules", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Cooperative Rules"
      assert html =~ "4 + player count"
      assert html =~ "Conservation token"
      assert html =~ "Appeal token"
    end

    test "can navigate to new game page", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      {:ok, _players_live, html} =
        index_live
        |> element("a", "Create New Game")
        |> render_click()
        |> follow_redirect(conn)

      assert html =~ "Game Setup"
    end
  end

  describe "Player setup (GameLive.Players)" do
    test "displays game setup with difficulty selection", %{conn: conn} do
      {:ok, _players_live, html} = live(conn, ~p"/games/new")

      assert html =~ "Game Setup"
      assert html =~ "Standard"
      assert html =~ "6 Rounds"
      assert html =~ "Hard"
      assert html =~ "5 Rounds"
      assert html =~ "Add Player"
    end

    test "can select difficulty", %{conn: conn} do
      {:ok, players_live, _html} = live(conn, ~p"/games/new")

      # Default is 6 rounds
      assert has_element?(players_live, "button.bg-blue-600", "Standard")

      # Click hard difficulty
      players_live
      |> element("button", "Hard")
      |> render_click()

      assert has_element?(players_live, "button.bg-blue-600", "Hard")
    end

    test "can add a player", %{conn: conn} do
      {:ok, players_live, _html} = live(conn, ~p"/games/new")

      # Initially no players
      assert has_element?(players_live, "p", "No players added yet")

      # Select color
      players_live
      |> element("button[phx-value-color='yellow']")
      |> render_click()

      # Enter name
      players_live
      |> element("input[name='name']")
      |> render_change(%{name: "Alice"})

      # Add player
      players_live
      |> element("form")
      |> render_submit()

      # Verify player was added
      html = render(players_live)
      assert html =~ "Alice"
      assert html =~ "Yellow"
      refute html =~ "No players added yet"
    end

    test "can add multiple players with different colors", %{conn: conn} do
      {:ok, players_live, _html} = live(conn, ~p"/games/new")

      # Add player 1 (yellow)
      players_live
      |> element("button[phx-value-color='yellow']")
      |> render_click()

      players_live
      |> element("input[name='name']")
      |> render_change(%{name: "Alice"})

      players_live
      |> element("form")
      |> render_submit()

      # Add player 2 (red)
      players_live
      |> element("button[phx-value-color='red']")
      |> render_click()

      players_live
      |> element("input[name='name']")
      |> render_change(%{name: "Bob"})

      players_live
      |> element("form")
      |> render_submit()

      # Verify both players
      html = render(players_live)
      assert html =~ "Alice"
      assert html =~ "Bob"
      assert html =~ "Players (2/4)"
    end

    test "displays goal information based on player count", %{conn: conn} do
      {:ok, players_live, _html} = live(conn, ~p"/games/new")

      # Add 1 player
      players_live
      |> element("button[phx-value-color='yellow']")
      |> render_click()

      players_live
      |> element("input[name='name']")
      |> render_change(%{name: "Alice"})

      players_live
      |> element("form")
      |> render_submit()

      # Should show 5 goals (4 + 1) and need 4 to win (4 * 1)
      html = render(players_live)
      assert html =~ "5 goals will be drawn"
      assert html =~ "Complete at least 4 goals"
    end

    test "can start game after adding players", %{conn: conn} do
      {:ok, players_live, _html} = live(conn, ~p"/games/new")

      # Add a player
      players_live
      |> element("button[phx-value-color='yellow']")
      |> render_click()

      players_live
      |> element("input[name='name']")
      |> render_change(%{name: "Alice"})

      players_live
      |> element("form")
      |> render_submit()

      # Start game button should appear
      assert has_element?(players_live, "button", "Start Game")

      # Click start game
      {:ok, _show_live, html} =
        players_live
        |> element("button", "Start Game")
        |> render_click()
        |> follow_redirect(conn)

      # Should be on game page
      assert html =~ "Cooperative Ark Nova"
      assert html =~ "Round 1 of 6"
    end
  end

  describe "Game play (GameLive.Show)" do
    setup %{conn: conn} do
      {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})

      {:ok, _player} =
        Game.create_player(%{
          game_id: game.id,
          name: "Alice",
          color: "yellow"
        })

      {:ok, game} = Game.start_game(game)

      %{conn: conn, game: game}
    end

    test "displays game information", %{conn: conn, game: game} do
      {:ok, _show_live, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "Cooperative Ark Nova"
      assert html =~ "Round 1 of 6"
      assert html =~ "Players"
      assert html =~ "Alice"
      assert html =~ "Win Conditions"
      assert html =~ "Goals"
    end

    test "displays player with maps", %{conn: conn, game: game} do
      {:ok, _show_live, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "Alice"
      assert html =~ "Maps:"
      # Maps should be displayed (can't test exact numbers as they're random)
    end

    test "displays all assigned goals", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      game = Game.get_game!(game.id)

      # Should have 5 goals (4 + 1 player)
      assert length(game.game_goals) == 5

      # Each goal should be displayed
      Enum.each(game.game_goals, fn game_goal ->
        assert has_element?(show_live, "p", game_goal.goal.description)
      end)
    end

    test "can toggle rules display", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      # Initially, Show Rules button should be visible
      assert has_element?(show_live, "button", "Show Rules")

      # Click show rules
      show_live
      |> element("button", "Show Rules")
      |> render_click()

      # Rules should now be visible
      assert has_element?(show_live, "h2", "Cooperative Rules")
      assert has_element?(show_live, "strong", "Sponsor money action:")

      # Button should now say "Hide Rules"
      assert has_element?(show_live, "button", "Hide Rules")

      # Click hide rules
      show_live
      |> element("button", "Hide Rules")
      |> render_click()

      # Rules should be hidden again
      refute has_element?(show_live, "h2", "Cooperative Rules")
      assert has_element?(show_live, "button", "Show Rules")
    end

    test "can claim a goal for a player", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      game = Game.get_game!(game.id)
      goal = List.first(game.game_goals)

      # Click the yellow player button for the first goal
      show_live
      |> element("button[phx-value-goal-id='#{goal.id}'][phx-value-color='yellow']")
      |> render_click()

      # Goal should be claimed
      game = Game.get_game!(game.id)
      goal = Enum.find(game.game_goals, &(&1.id == goal.id))
      assert "yellow" in goal.claimed_by
    end

    test "can toggle conservation status", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      players = Game.list_players(game.id)
      player = List.first(players)

      # Initially conservation is not met
      refute player.conservation_met

      # Click the conservation checkbox
      show_live
      |> element("input[type='checkbox'][phx-value-player-id='#{player.id}']")
      |> render_click()

      # Conservation should now be met
      players = Game.list_players(game.id)
      player = Enum.find(players, &(&1.id == player.id))
      assert player.conservation_met
    end

    test "displays goal progress", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      # Should show goal count (0/4 initially for 1 player)
      assert has_element?(show_live, "span", "0 / 4")

      # Claim a goal
      game = Game.get_game!(game.id)
      goal = List.first(game.game_goals)

      show_live
      |> element("button[phx-value-goal-id='#{goal.id}'][phx-value-color='yellow']")
      |> render_click()

      # Should now show 1/4
      assert has_element?(show_live, "span", "1 / 4")
    end

    test "can advance to next round", %{conn: conn, game: game} do
      {:ok, show_live, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "Round 1 of 6"

      # Click next round
      show_live
      |> element("button", "Next Round")
      |> render_click()

      assert has_element?(show_live, "p", "Round 2 of 6")
    end

    test "next round button disappears on final round", %{conn: conn, game: game} do
      # Advance to round 6
      game = Game.get_game!(game.id)
      {:ok, game} = Game.next_round(game)
      {:ok, game} = Game.next_round(game)
      {:ok, game} = Game.next_round(game)
      {:ok, game} = Game.next_round(game)
      {:ok, _game} = Game.next_round(game)

      # Reload the page
      {:ok, show_live, html} = live(conn, ~p"/games/#{game.id}")

      assert html =~ "Round 6 of 6"
      # Next round button should not be present
      refute has_element?(show_live, "button", "Next Round")
    end

    test "can finish game and see results", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      # Finish the game
      show_live
      |> element("button", "Finish Game")
      |> render_click()

      # Should show game finished
      assert has_element?(show_live, "h2", "Game Finished!")
      assert has_element?(show_live, "h3", "Win Conditions")
    end

    test "displays win when all conditions met", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      game = Game.get_game!(game.id)
      players = Game.list_players(game.id)
      player = List.first(players)

      # Claim 4 goals
      game.game_goals
      |> Enum.take(4)
      |> Enum.each(fn goal ->
        show_live
        |> element("button[phx-value-goal-id='#{goal.id}'][phx-value-color='yellow']")
        |> render_click()
      end)

      # Mark conservation as met
      show_live
      |> element("input[type='checkbox'][phx-value-player-id='#{player.id}']")
      |> render_click()

      # Finish game
      show_live
      |> element("button", "Finish Game")
      |> render_click()

      # Should show victory
      assert has_element?(show_live, "p", "Victory! Both win conditions met!")
    end

    test "displays loss when goal condition not met", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      players = Game.list_players(game.id)
      player = List.first(players)

      # Only claim 2 goals (need 4)
      game = Game.get_game!(game.id)

      game.game_goals
      |> Enum.take(2)
      |> Enum.each(fn goal ->
        show_live
        |> element("button[phx-value-goal-id='#{goal.id}'][phx-value-color='yellow']")
        |> render_click()
      end)

      # Mark conservation as met
      show_live
      |> element("input[type='checkbox'][phx-value-player-id='#{player.id}']")
      |> render_click()

      # Finish game
      show_live
      |> element("button", "Finish Game")
      |> render_click()

      # Should show loss
      assert has_element?(show_live, "p", "Goal count not met - better luck next time!")
    end

    test "displays loss when conservation not met", %{conn: conn, game: game} do
      {:ok, show_live, _html} = live(conn, ~p"/games/#{game.id}")

      game = Game.get_game!(game.id)

      # Claim all 5 goals
      game.game_goals
      |> Enum.each(fn goal ->
        show_live
        |> element("button[phx-value-goal-id='#{goal.id}'][phx-value-color='yellow']")
        |> render_click()
      end)

      # Don't mark conservation as met

      # Finish game
      show_live
      |> element("button", "Finish Game")
      |> render_click()

      # Should show loss
      assert has_element?(
               show_live,
               "p",
               "Not all players have Conservation >= Appeal - better luck next time!"
             )
    end
  end

  describe "4 player game flow" do
    test "complete game with 4 players", %{conn: conn} do
      {:ok, players_live, _html} = live(conn, ~p"/games/new")

      # Add 4 players
      players_data = [
        {"Alice", "yellow"},
        {"Bob", "red"},
        {"Charlie", "blue"},
        {"Diana", "black"}
      ]

      Enum.each(players_data, fn {name, color} ->
        players_live
        |> element("button[phx-value-color='#{color}']")
        |> render_click()

        players_live
        |> element("input[name='name']")
        |> render_change(%{name: name})

        players_live
        |> element("form")
        |> render_submit()
      end)

      # Verify all players added
      html = render(players_live)
      assert html =~ "Players (4/4)"
      assert html =~ "8 goals will be drawn"
      assert html =~ "Complete at least 16 goals"

      # Start game
      {:ok, show_live, html} =
        players_live
        |> element("button", "Start Game")
        |> render_click()
        |> follow_redirect(conn)

      # Verify game started
      assert html =~ "Round 1 of 6"
      assert html =~ "Alice"
      assert html =~ "Bob"
      assert html =~ "Charlie"
      assert html =~ "Diana"

      # Verify all players have maps
      Enum.each(["Alice", "Bob", "Charlie", "Diana"], fn name ->
        assert has_element?(show_live, "div", name)
        # The parent div should contain Maps: text
      end)

      # Extract goal IDs and player IDs from the rendered HTML
      html_content = render(show_live)

      # Extract all unique goal IDs from the HTML
      goal_ids =
        Regex.scan(~r/phx-value-goal-id="([^"]+)"/, html_content)
        |> Enum.map(fn [_, id] -> id end)
        |> Enum.uniq()

      # Extract all player IDs from checkboxes
      player_ids =
        Regex.scan(~r/phx-value-player-id="([^"]+)"/, html_content)
        |> Enum.map(fn [_, id] -> id end)
        |> Enum.uniq()

      # Each player claims all goals (32 total claims for 8 goals * 4 players)
      Enum.each(goal_ids, fn goal_id ->
        Enum.each(["yellow", "red", "blue", "black"], fn color ->
          show_live
          |> element("button[phx-value-goal-id='#{goal_id}'][phx-value-color='#{color}']")
          |> render_click()
        end)
      end)

      # Mark all conservation as met
      Enum.each(player_ids, fn player_id ->
        show_live
        |> element("input[type='checkbox'][phx-value-player-id='#{player_id}']")
        |> render_click()
      end)

      # Finish game
      show_live
      |> element("button", "Finish Game")
      |> render_click()

      # Verify win
      assert has_element?(show_live, "p", "Victory! Both win conditions met!")
      assert has_element?(show_live, "p", "Goal Count: 32 / 16")
    end
  end
end
