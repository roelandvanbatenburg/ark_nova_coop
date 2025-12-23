# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ArkNovaCoop.Repo.insert!(%ArkNovaCoop.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ArkNovaCoop.Repo
alias ArkNovaCoop.Game.Goal

# Delete existing goals to avoid duplicates when re-running seeds
Repo.delete_all(Goal)

# Insert all cooperative Ark Nova goals
goals = [
  # Page 1
  "Have 2 5-space enclosures with animals",
  "Have 4 action cards upgraded",
  "Have 50 money",
  "Have conservation token pass appeal token by end of round 5",
  "Have 4 association workers",
  "Have no large animals (enclosure size 4+ required, eval at end)",
  "Spend 25+ money on a single animal",
  "Release an animal into the wild",
  "Have 4 herbivores in 2 enclosures",

  # Page 2
  "Have a completely filled zoo board",
  "Have 3+ cubes on conservation projects",
  "Have 2+ unique enclosures",
  "Have 2+ special enclosures with at least 2+ cubes on each",
  "Have 3+ partner zoos and 2+ universities",
  "Have 5+ categories of animal (herbivore, carnivore, etc)",
  "Have 1+ animal from each continent",
  "Have 5+ sponsors in play",
  "Have 8+ different animals in play",

  # Page 3
  "Build 6+ pavilions",
  "Build 4+ kiosks",
  "Have 4+ animals from one continent",
  "Have 4+ animals of the same category",
  "Reach the last section of the reputation track",
  "Build all enclosure types (size 1-5, aviary, reptile, petting zoo)"
]

Enum.each(goals, fn description ->
  Repo.insert!(%Goal{description: description})
end)

IO.puts("Seeded #{length(goals)} goals successfully!")
