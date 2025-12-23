defmodule ArkNovaCoopWeb.GameLive.Index do
  @moduledoc false
  use ArkNovaCoopWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-12">
      <div class="text-center mb-12">
        <h1 class="text-4xl font-bold text-gray-900 mb-4">Ark Nova Cooperative</h1>
        <p class="text-xl text-gray-600">Track your cooperative zoo-building adventure</p>
      </div>

      <div class="bg-white shadow-lg rounded-lg p-8 mb-8">
        <h2 class="text-2xl font-semibold mb-4">Start a New Game</h2>
        <p class="text-gray-600 mb-6">
          Create a new cooperative game and track your team's progress toward completing goals.
        </p>
        <.link
          navigate={~p"/games/new"}
          class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          Create New Game
        </.link>
      </div>

      <div class="bg-blue-50 rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">Cooperative Rules</h3>
        <p class="text-gray-700 mb-4">
          In the cooperative variant of Ark Nova, players work together to achieve shared goals.
          Each game draws <strong>4 + player count</strong>
          goals that must be claimed by players.
          The game lasts <strong>5 rounds</strong>
          for a hard game or <strong>6 rounds</strong>
          for a standard game.
        </p>

        <div class="bg-white rounded-lg p-4 mb-4">
          <h4 class="font-semibold text-gray-800 mb-2">Win Conditions (both required):</h4>
          <ol class="list-decimal list-inside space-y-2 text-gray-700">
            <li>
              Each player's <strong>Conservation token</strong>
              must pass or equal their <strong>Appeal token</strong>
              (i.e., end game score >= 0)
            </li>
            <li>
              Total claimed goals must be >= <strong>4 × player count</strong>
            </li>
          </ol>
        </div>

        <div class="space-y-4 text-gray-700">
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

        <div class="mt-4 pt-4 border-t border-blue-200">
          <p class="text-sm text-gray-600">
            <a
              href="https://boardgamegeek.com/thread/3174549/ark-nova-full-cooperative-variant-with-endgame-goa"
              target="_blank"
              rel="noopener noreferrer"
              class="text-blue-700 hover:text-blue-800 underline"
            >
              Full rules on BoardGameGeek →
            </a>
          </p>
        </div>
      </div>
    </div>
    """
  end
end
