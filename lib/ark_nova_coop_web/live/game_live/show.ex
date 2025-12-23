defmodule ArkNovaCoopWeb.GameLive.Show do
  @moduledoc false
  use ArkNovaCoopWeb, :live_view

  alias ArkNovaCoop.Game

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    game = Game.get_game!(id)
    players = Game.list_players(id)

    {:ok,
     socket
     |> assign(:game, game)
     |> assign(:players, players)
     |> assign(:show_rules, false)}
  end

  @impl true
  def handle_event("toggle_goal", %{"goal-id" => goal_id, "color" => color}, socket) do
    Game.toggle_goal_claim(goal_id, color)
    game = Game.get_game!(socket.assigns.game.id)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("next_round", _params, socket) do
    case Game.next_round(socket.assigns.game) do
      {:ok, game} ->
        {:noreply, assign(socket, :game, game)}

      {:error, :game_finished} ->
        {:noreply, put_flash(socket, :info, "Game is finished!")}
    end
  end

  @impl true
  def handle_event("finish_game", _params, socket) do
    {:ok, game} = Game.finish_game(socket.assigns.game)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("toggle_rules", _params, socket) do
    {:noreply, assign(socket, :show_rules, !socket.assigns.show_rules)}
  end

  @impl true
  def handle_event("toggle_conservation", %{"player-id" => player_id}, socket) do
    Game.toggle_player_conservation(player_id)
    game = Game.get_game!(socket.assigns.game.id)
    players = Game.list_players(socket.assigns.game.id)
    {:noreply, socket |> assign(:game, game) |> assign(:players, players)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 py-8">
      <div class="mb-8">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h1 class="text-3xl font-bold text-gray-900">Cooperative Ark Nova</h1>
            <p class="text-gray-600 mt-1">
              Round {@game.current_round} of {@game.total_rounds}
            </p>
          </div>
          <div class="flex gap-3">
            <button
              type="button"
              phx-click="toggle_rules"
              class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
            >
              {if @show_rules, do: "Hide Rules", else: "Show Rules"}
            </button>
            <%= if @game.status == "playing" && @game.current_round < @game.total_rounds do %>
              <button
                type="button"
                phx-click="next_round"
                class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                Next Round
              </button>
            <% end %>
            <%= if @game.status == "playing" do %>
              <button
                type="button"
                phx-click="finish_game"
                class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
              >
                Finish Game
              </button>
            <% end %>
          </div>
        </div>

        <%= if @show_rules do %>
          <div class="bg-blue-50 rounded-lg p-6 mb-6">
            <h2 class="text-xl font-semibold mb-4">Cooperative Rules</h2>
            <div class="space-y-4 text-gray-700">
              <div>
                <p>
                  <strong>Setup:</strong> Draw {length(@game.game_goals)} goals (4 + player count).
                  The game lasts {@game.total_rounds} rounds.
                </p>
              </div>

              <div class="border-l-4 border-blue-600 pl-4 py-2 bg-blue-100 rounded">
                <p class="font-semibold mb-2">Win Conditions (both must be met):</p>
                <ol class="list-decimal list-inside space-y-1">
                  <li>
                    Each player's <strong>Conservation token</strong>
                    must pass or equal their <strong>Appeal token</strong>
                    (i.e., end game score >= 0)
                  </li>
                  <li>
                    Total claimed goals must be >= <strong>{Game.required_goals_count(@game)}</strong>
                    (4 × player count)
                  </li>
                </ol>
              </div>

              <div>
                <p class="font-semibold mb-2">Changed Game Rules:</p>
                <ul class="list-disc list-inside space-y-1 ml-2">
                  <li>
                    <strong>Sponsor money action:</strong>
                    Advance the break token twice for any strength value
                  </li>
                  <li>
                    <strong>Passing action:</strong>
                    Advance the break token once, as well as taking an X token, and moving a card
                  </li>
                </ul>
              </div>

              <div>
                <p class="font-semibold mb-2">New Game Rules:</p>
                <ul class="list-disc list-inside space-y-1 ml-2">
                  <li>
                    <strong>Trade action:</strong>
                    Advance the break token once, then the player may trade a card with another player. Either side may give 3 money instead of a card
                  </li>
                  <li>
                    <strong>Mark endgame goal completion:</strong>
                    This is free, and may be done as soon as completion is gained, with some exceptions (noted on goal cards). Any number of players can mark each goal
                  </li>
                </ul>
              </div>
            </div>
          </div>
        <% end %>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-xl font-semibold mb-4">Players</h2>
            <div class="space-y-3">
              <%= for player <- @players do %>
                <div class="flex items-center gap-2">
                  <div class={[
                    "w-8 h-8 rounded-full flex items-center justify-center text-white font-semibold text-sm",
                    player_color_class(player.color)
                  ]}>
                    {String.first(player.name) |> String.upcase()}
                  </div>
                  <div class="flex-1">
                    <div class="flex items-center gap-2">
                      <span class="font-medium">{player.name}</span>
                      <span class="text-sm text-gray-500">
                        ({player_goals_count(@game, player.color)} goals)
                      </span>
                      <%= if @game.starting_player == player.color do %>
                        <span class="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded font-medium">
                          Starting Player
                        </span>
                      <% end %>
                    </div>
                    <%= if player.map1 && player.map2 do %>
                      <div class="text-xs text-gray-600 mt-0.5">
                        Maps: {player.map1} / {player.map2}
                      </div>
                    <% end %>
                  </div>
                  <%= if @game.status == "playing" do %>
                    <label class="flex items-center gap-1 ml-auto cursor-pointer">
                      <input
                        type="checkbox"
                        phx-click="toggle_conservation"
                        phx-value-player-id={player.id}
                        checked={player.conservation_met}
                        class="w-4 h-4 text-green-600 bg-gray-100 border-gray-300 rounded focus:ring-green-500"
                      />
                      <span class="text-xs text-gray-600">Conservation ≥ Appeal</span>
                    </label>
                  <% else %>
                    <%= if player.conservation_met do %>
                      <span class="text-xs bg-green-100 text-green-700 px-2 py-1 rounded font-medium ml-auto">
                        ✓ Conservation ≥ Appeal
                      </span>
                    <% end %>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

          <div class={[
            "shadow rounded-lg p-6",
            if(Game.goal_condition_met?(@game), do: "bg-green-50", else: "bg-yellow-50")
          ]}>
            <h2 class="text-xl font-semibold mb-4">Win Conditions</h2>
            <div class="space-y-3">
              <div>
                <div class="flex items-center justify-between mb-1">
                  <span class="text-sm font-medium text-gray-700">Goal Count</span>
                  <span class={[
                    "text-sm font-bold",
                    if(Game.goal_condition_met?(@game), do: "text-green-600", else: "text-gray-600")
                  ]}>
                    {Game.total_goal_claims(@game)} / {Game.required_goals_count(@game)}
                  </span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div
                    class={[
                      "h-2 rounded-full transition-all",
                      if(Game.goal_condition_met?(@game), do: "bg-green-600", else: "bg-blue-600")
                    ]}
                    style={"width: #{min(100, div(Game.total_goal_claims(@game) * 100, Game.required_goals_count(@game)))}%"}
                  >
                  </div>
                </div>
              </div>
              <div class="pt-2 border-t border-gray-200">
                <div class="mb-2">
                  <span class="text-sm font-medium text-gray-700">Conservation ≥ Appeal</span>
                </div>
                <div class="space-y-1">
                  <%= for player <- @players do %>
                    <div class="flex items-center justify-between text-sm">
                      <span class="text-gray-600">{player.name}</span>
                      <%= if player.conservation_met do %>
                        <span class="text-green-600 font-semibold">✓</span>
                      <% else %>
                        <span class="text-gray-400">—</span>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mb-6">
        <h2 class="text-2xl font-semibold mb-4">
          Goals
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for game_goal <- @game.game_goals do %>
            <div class={[
              "bg-white shadow rounded-lg p-5 transition-all",
              if(length(game_goal.claimed_by || []) > 0,
                do: "border-2 border-green-400",
                else: "border border-gray-200"
              )
            ]}>
              <div class="mb-4">
                <p class="text-gray-800 font-medium leading-relaxed">
                  {game_goal.goal.description}
                </p>
              </div>

              <%= if @game.status == "playing" do %>
                <div>
                  <p class="text-xs text-gray-500 mb-2">Toggle claims:</p>
                  <div class="flex gap-2">
                    <%= for player <- @players do %>
                      <button
                        type="button"
                        phx-click="toggle_goal"
                        phx-value-goal-id={game_goal.id}
                        phx-value-color={player.color}
                        class={[
                          "w-10 h-10 rounded-full hover:scale-110 transition-all relative",
                          player_color_class(player.color),
                          if(Game.goal_claimed_by?(game_goal, player.color),
                            do: "ring-4 ring-offset-2 ring-green-500",
                            else: "opacity-50"
                          )
                        ]}
                        title={player.name}
                      >
                        <%= if Game.goal_claimed_by?(game_goal, player.color) do %>
                          <span class="absolute inset-0 flex items-center justify-center text-white font-bold text-lg">
                            ✓
                          </span>
                        <% end %>
                      </button>
                    <% end %>
                  </div>
                </div>
              <% else %>
                <%= if length(game_goal.claimed_by || []) == 0 do %>
                  <p class="text-sm text-gray-500">Not claimed</p>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <%= if @game.status == "finished" do %>
        <div class={[
          "border-2 rounded-lg p-8",
          if(Game.goal_condition_met?(@game),
            do: "bg-green-50 border-green-500",
            else: "bg-red-50 border-red-500"
          )
        ]}>
          <h2 class={[
            "text-3xl font-bold mb-4 text-center",
            if(Game.goal_condition_met?(@game), do: "text-green-800", else: "text-red-800")
          ]}>
            Game Finished!
          </h2>

          <div class="max-w-2xl mx-auto space-y-4">
            <div class="bg-white rounded-lg p-4">
              <h3 class="font-semibold text-lg mb-3 text-gray-800">Win Conditions</h3>
              <div class="space-y-3">
                <div class="flex items-start gap-3">
                  <div class={[
                    "flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center text-white font-bold text-sm",
                    if(Game.goal_condition_met?(@game), do: "bg-green-600", else: "bg-red-600")
                  ]}>
                    {if Game.goal_condition_met?(@game), do: "✓", else: "✗"}
                  </div>
                  <div class="flex-1">
                    <p class="font-medium text-gray-800">
                      Goal Count: {Game.total_goal_claims(@game)} / {Game.required_goals_count(@game)}
                    </p>
                    <p class="text-sm text-gray-600">
                      <%= if Game.goal_condition_met?(@game) do %>
                        Requirement met!
                      <% else %>
                        Need {Game.required_goals_count(@game) - Game.total_goal_claims(@game)} more goals
                      <% end %>
                    </p>
                  </div>
                </div>

                <div class="flex items-start gap-3">
                  <div class={[
                    "flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center text-white font-bold text-sm",
                    if(Game.all_players_conservation_met?(@game.id),
                      do: "bg-green-600",
                      else: "bg-red-600"
                    )
                  ]}>
                    {if Game.all_players_conservation_met?(@game.id), do: "✓", else: "✗"}
                  </div>
                  <div class="flex-1">
                    <p class="font-medium text-gray-800">Conservation >= Appeal for all players</p>
                    <div class="mt-2 space-y-1">
                      <%= for player <- @players do %>
                        <div class="flex items-center gap-2 text-sm">
                          <%= if player.conservation_met do %>
                            <span class="text-green-600 font-semibold">✓</span>
                          <% else %>
                            <span class="text-red-600 font-semibold">✗</span>
                          <% end %>
                          <span class="text-gray-700">{player.name}</span>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <%= if Game.goal_condition_met?(@game) && Game.all_players_conservation_met?(@game.id) do %>
              <div class="text-center">
                <p class="text-xl font-semibold text-green-800">
                  Victory! Both win conditions met!
                </p>
              </div>
            <% else %>
              <div class="text-center">
                <p class="text-xl font-semibold text-red-800">
                  <%= cond do %>
                    <% !Game.goal_condition_met?(@game) && !Game.all_players_conservation_met?(@game.id) -> %>
                      Both win conditions not met - better luck next time!
                    <% !Game.goal_condition_met?(@game) -> %>
                      Goal count not met - better luck next time!
                    <% !Game.all_players_conservation_met?(@game.id) -> %>
                      Not all players have Conservation >= Appeal - better luck next time!
                  <% end %>
                </p>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp player_color_class("yellow"), do: "bg-yellow-500"
  defp player_color_class("red"), do: "bg-red-600"
  defp player_color_class("blue"), do: "bg-blue-600"
  defp player_color_class("black"), do: "bg-gray-900"

  defp player_goals_count(game, color) do
    Enum.count(game.game_goals, fn gg -> color in (gg.claimed_by || []) end)
  end
end
