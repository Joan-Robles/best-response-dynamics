# Title: Game Theory Simulation
# Parameters --------------------------------------------------------------
n_players <- 10
n_games <- 1e4
set.seed(1928) # For reproducibility

# Call functions ---------------------------------------------------------------------
source("functions.R")

game_results <- run_many_games(n_games = n_games, n_players = n_players)

summary_game_results(game_results, n_players = n_players)

