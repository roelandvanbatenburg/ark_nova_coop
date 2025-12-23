# Ark Nova Cooperative Tracker

A Phoenix LiveView webapp to initialize and track cooperative games of Ark Nova. This app helps players manage their cooperative zoo-building adventure by tracking goals, rounds, and player achievements.

The app can be found here: <https://ark-nova-coop.fly.dev/>

## Features

- **Game Setup**: Configure games for 1-4 players with standard (6 rounds) or hard (5 rounds) difficulty
- **Goal Management**: Automatically draws 4 + player count goals from a seeded database
- **Player Registration**: Players select colors (yellow, red, blue, black) and enter names
- **Live Tracking**: Real-time goal claiming and round progression
- **Cooperative Rules**: Built-in rules display for the cooperative variant
- **Starting Player**: Picks a player to start the game
- **Maps**: Assigns two maps to each player, consistent with restictions around map availability

## Prerequisites

- Elixir 1.18+ and Erlang/OTP 27+

## Usage

### Starting a New Game

1. Visit the homepage and click "Create New Game"
2. Choose difficulty: Standard (6 rounds) or Hard (5 rounds)
3. Add players (1-4):
   - Enter player name
   - Select player color (yellow, red, blue, black)
   - Click "Add Player"
   - Repeat for each player
4. The app automatically calculates:
   - Goals to draw: 4 + player count
   - Goals needed to win: 4 × player count
5. Click "Start Game" when all players are added

### Playing the Game

1. The game board displays all assigned goals
2. Click a colored circle under a goal to claim it for that player
3. Use "Next Round" to advance through rounds
4. Click "Unclaim" to remove a claim if needed
5. Click "Finish Game" when done to see final results

### Managing Goals

The app comes pre-seeded with 25 cooperative goals from the official variant. To add new goals:

```bash
mix add_goal "Your new goal description here"
```

## Cooperative Rules

- **Setup**: Draw 4 + player count goals at the start of each game
- **Gameplay**: Players work together to achieve drawn goals over 5-6 rounds
- **Goal Claiming**: Players claim goals they've completed by clicking on them

### Win Conditions (both must be met)

1. **Conservation >= Appeal**: Each player's Conservation token must pass or equal their Appeal token (i.e., end game score >= 0). This is tracked on the physical game board.

2. **Goal Count**: The total count of claimed goals must be >= 4 × player count. The app automatically tracks this and displays progress toward the requirement.

Players win if BOTH conditions are satisfied at the end of the game!

Full rules available at: [BoardGameGeek Thread](https://boardgamegeek.com/thread/3174549/ark-nova-full-cooperative-variant-with-endgame-goa)

## Development

### Running Tests

```bash
mix check
```

### Database Reset

```bash
mix ecto.reset
```

This drops the database, recreates it, runs migrations, and re-seeds the goals.
