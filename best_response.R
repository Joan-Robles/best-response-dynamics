# Title: Game Theory Simulation
# Parameters --------------------------------------------------------------
n_players <- seq(2, 10, 2) # Number of players in the game
n_games <- 1e5 # Simulations per player count
set.seed(1804) # For reproducibility

# Call functions 
source("functions.R")

# Save the plots in a folder called plots

if (!dir.exists("plots")) dir.create("plots")

for (i in n_players) {
  cat("Running game with", i, "players...\n")
  png(
    filename = sprintf("plots/game_results_%d_players.png", i),
    width    = 10, height = 6, units = "in", res = 300
  )
  summary_game_results(run_many_games(n_games, i), n_players = i)
  dev.off()
}
