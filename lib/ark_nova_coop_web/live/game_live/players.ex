defmodule ArkNovaCoopWeb.GameLive.Players do
  @moduledoc false
  use ArkNovaCoopWeb, :live_view

  alias ArkNovaCoop.Game

  @impl true
  def mount(params, _session, socket) do
    game =
      case params do
        %{"id" => id} ->
          Game.get_game!(id)

        _ ->
          # Create a new game with default 6 rounds
          {:ok, game} = Game.create_game(%{total_rounds: 6, status: "setup"})
          game
      end

    players = Game.list_players(game.id)

    {:ok,
     socket
     |> assign(:game, game)
     |> assign(:players, players)
     |> assign(:new_player_name, "")
     |> assign(:selected_color, nil)
     |> assign(:available_colors, Game.available_colors(game.id))}
  end

  @impl true
  def handle_event("update_rounds", %{"rounds" => rounds}, socket) do
    {:ok, game} =
      Game.update_game(socket.assigns.game, %{total_rounds: String.to_integer(rounds)})

    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("select_color", %{"color" => color}, socket) do
    {:noreply, assign(socket, :selected_color, color)}
  end

  @impl true
  def handle_event("update_name", %{"name" => name}, socket) do
    {:noreply, assign(socket, :new_player_name, name)}
  end

  @impl true
  def handle_event("add_player", _params, socket) do
    if socket.assigns.selected_color && socket.assigns.new_player_name != "" do
      case Game.create_player(%{
             game_id: socket.assigns.game.id,
             name: socket.assigns.new_player_name,
             color: socket.assigns.selected_color
           }) do
        {:ok, _player} ->
          players = Game.list_players(socket.assigns.game.id)
          available_colors = Game.available_colors(socket.assigns.game.id)

          {:noreply,
           socket
           |> assign(:players, players)
           |> assign(:available_colors, available_colors)
           |> assign(:new_player_name, "")
           |> assign(:selected_color, nil)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to add player")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please select a color and enter a name")}
    end
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    players = socket.assigns.players

    if not Enum.empty?(players) and length(players) <= 4 do
      case Game.start_game(socket.assigns.game) do
        {:ok, _game} ->
          {:noreply, push_navigate(socket, to: ~p"/games/#{socket.assigns.game.id}")}

        {:error, :no_players} ->
          {:noreply, put_flash(socket, :error, "Add at least one player to start")}
      end
    else
      {:noreply, put_flash(socket, :error, "Add 1-4 players to start")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-12">
      <div class="mb-6">
        <.link navigate={~p"/"} class="text-blue-600 hover:text-blue-700">
          ← Back to Home
        </.link>
      </div>

      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900 mb-4">Game Setup</h1>

        <div class="bg-white shadow-lg rounded-lg p-6">
          <label class="block text-lg font-medium text-gray-700 mb-4">
            Difficulty
          </label>
          <div class="grid grid-cols-2 gap-4 mb-2">
            <button
              type="button"
              phx-click="update_rounds"
              phx-value-rounds="6"
              class={[
                "p-4 text-center rounded-lg font-semibold transition-colors",
                if(@game.total_rounds == 6,
                  do: "bg-blue-600 text-white",
                  else: "bg-gray-100 text-gray-700 hover:bg-gray-200"
                )
              ]}
            >
              <div class="text-xl mb-1">Standard</div>
              <div class="text-sm opacity-90">6 Rounds</div>
            </button>
            <button
              type="button"
              phx-click="update_rounds"
              phx-value-rounds="5"
              class={[
                "p-4 text-center rounded-lg font-semibold transition-colors",
                if(@game.total_rounds == 5,
                  do: "bg-blue-600 text-white",
                  else: "bg-gray-100 text-gray-700 hover:bg-gray-200"
                )
              ]}
            >
              <div class="text-xl mb-1">Hard</div>
              <div class="text-sm opacity-90">5 Rounds</div>
            </button>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div class="bg-white shadow-lg rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">Add Player</h2>

          <form phx-submit="add_player" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Player Name
              </label>
              <input
                type="text"
                phx-change="update_name"
                value={@new_player_name}
                name="name"
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter name"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Select Color
              </label>
              <div class="grid grid-cols-2 gap-3">
                <%= for color <- @available_colors do %>
                  <button
                    type="button"
                    phx-click="select_color"
                    phx-value-color={color}
                    class={[
                      "px-4 py-3 rounded-lg font-semibold text-white transition-all",
                      color_class(color),
                      if(@selected_color == color,
                        do: "ring-4 ring-offset-2 ring-gray-400 scale-105",
                        else: ""
                      )
                    ]}
                  >
                    {String.capitalize(color)}
                  </button>
                <% end %>
              </div>
              <%= if @available_colors == [] do %>
                <p class="text-sm text-gray-500 mt-2">All colors taken (max 4 players)</p>
              <% end %>
            </div>

            <button
              type="submit"
              disabled={
                @selected_color == nil || @new_player_name == "" || length(@available_colors) == 0
              }
              class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              Add Player
            </button>
          </form>
        </div>

        <div class="bg-white shadow-lg rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">
            Players ({length(@players)}/4)
          </h2>

          <%= if @players == [] do %>
            <p class="text-gray-500 text-center py-8">No players added yet</p>
          <% else %>
            <ul class="space-y-3">
              <%= for player <- @players do %>
                <li class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                  <div class={[
                    "w-10 h-10 rounded-full flex items-center justify-center text-white font-semibold",
                    color_class(player.color)
                  ]}>
                    {String.first(player.name) |> String.upcase()}
                  </div>
                  <div class="flex-1">
                    <div class="font-semibold">{player.name}</div>
                    <div class="text-sm text-gray-500">
                      {String.capitalize(player.color)}
                    </div>
                  </div>
                </li>
              <% end %>
            </ul>
          <% end %>

          <%= if length(@players) > 0 do %>
            <div class="mt-4 p-3 bg-blue-50 rounded-lg text-sm text-gray-700">
              <p>
                <strong>Goals:</strong>
                {4 + length(@players)} goals will be drawn
              </p>
              <p class="mt-1">
                <strong>To win:</strong> Complete at least {4 * length(@players)} goals
              </p>
            </div>

            <button
              type="button"
              phx-click="start_game"
              class="w-full mt-6 px-4 py-3 bg-green-600 text-white rounded-md hover:bg-green-700 font-semibold"
            >
              Start Game
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp color_class("yellow"), do: "bg-yellow-500"
  defp color_class("red"), do: "bg-red-600"
  defp color_class("blue"), do: "bg-blue-600"
  defp color_class("black"), do: "bg-gray-900"
end
