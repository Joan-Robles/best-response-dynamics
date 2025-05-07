#' Set up a random game payoff array
#'
#' Creates an n-dimensional array of uniform payoffs for a game with `n_players` and
#' a fixed number of `strategies` per player.
#'
#' @param n_players Integer. Number of players in the game.
#' @param strategies Integer. Number of strategies available to each player (default: 2).
#' @return Numeric array of dimension `c(n_players, rep(strategies, n_players))` containing random payoffs.
#' @examples
#' set_game(3)
#' set_game(4, strategies = 3)
#' @export
set_game <- function(n_players, strategies = 2) {
  array_size <- c(n_players, rep(strategies, n_players))
  game <- array(data = runif(prod(array_size)), dim = array_size)
  game
}


#' Find first FALSE in a logical vector
#'
#' Returns the index of the first `FALSE` value in `x`, or `NA_integer_` if none.
#'
#' @param x Logical vector to search.
#' @return Integer index of first FALSE, or `NA_integer_` if no FALSE is found.
#' @examples
#' first_false(c(TRUE, TRUE, FALSE, TRUE)) # 3
#' first_false(c(TRUE, TRUE))               # NA
#' @export
first_false <- function(x) match(FALSE, x, nomatch = NA_integer_)


#' Flip binary vector elements (0 ↔ 1)
#'
#' Transforms 0s to 1s and 1s to 0s in a numeric or integer vector.
#'
#' @param x Numeric or integer vector containing only 0s and 1s.
#' @return Integer vector with values flipped (1 becomes 0, 0 becomes 1).
#' @examples
#' flip01(c(0, 1, 0, 1)) # c(1, 0, 1, 0)
#' @export
flip01 <- function(x) { 1L - as.integer(x) }


#' Check for duplicate rows in a matrix or data.frame
#'
#' @param m Matrix or data.frame whose rows will be checked.
#' @return Logical `TRUE` if any duplicate rows exist, otherwise `FALSE`.
#' @examples
#' has_dup_rows(matrix(c(1,2,3,1,2,3), nrow = 2, byrow = TRUE)) # TRUE
#' has_dup_rows(matrix(1:4, nrow = 2))                            # FALSE
#' @export
has_dup_rows <- function(m) {
  anyDuplicated(as.data.frame(m)) > 0L
}


#' Determine a player's next move in the game
#'
#' Compares current utility to the utility after flipping the selected player's strategy.
#' Updates the strategy profile and agreement status accordingly.
#'
#' @param game Numeric array of payoffs as produced by `set_game()`.
#' @param selected_player Integer. Index of the player whose move is evaluated.
#' @param strategy Integer vector of length `n_players` with current strategies (0/1).
#' @param agree_status Logical vector of length `n_players` indicating which players have agreed.
#' @param is_new Logical flag (default `FALSE`). Indicates if the strategy was changed this call.
#' @return A list with elements:
#'   * `strategy`: Updated strategy vector.
#'   * `agree_status`: Updated agreement status vector.
#'   * `is_new`: `TRUE` if the selected player changed strategy, else `FALSE`.
#' @examples
#' g <- set_game(3)
#' get_player_move(g, 1, c(0,0,0), c(FALSE, FALSE, FALSE))
#' @export
get_player_move <- function(game, selected_player, strategy, agree_status, is_new = FALSE) {
  idx_current <- as.list(c(selected_player, strategy + 1L))
  u_current   <- do.call("[", c(list(game), idx_current))

  changed_strat <- strategy
  changed_strat[selected_player] <- 1L - strategy[selected_player]
  idx_changed  <- as.list(c(selected_player, changed_strat + 1L))
  u_change     <- do.call("[", c(list(game), idx_changed))

  if (u_change > u_current) {
    strategy[selected_player] <- changed_strat[selected_player]
    agree_status[] <- FALSE
    agree_status[selected_player] <- TRUE
    is_new <- TRUE
  } else {
    agree_status[selected_player] <- TRUE
  }

  list(
    strategy     = strategy,
    agree_status = agree_status,
    is_new       = is_new
  )
}


#' Play a single game until equilibrium or cycle detection
#'
#' Iteratively applies `get_player_move()` until all players agree or a strategy profile repeats.
#'
#' @param n_players Integer. Number of players.
#' @param game Numeric payoff array from `set_game()`.
#' @return Character vector of length 2:
#'   1. Status: "Equilibrium found" or "Equilibrium not found"
#'   2. Number of iterations performed.
#' @examples
#' play_game(3, set_game(3))
#' @export
play_game <- function(n_players, game) {
  strategy        <- integer(n_players)
  agree_status    <- rep(FALSE, n_players)
  used_strategies <- rbind(strategy)
  iteration_count <- 0L 
  movements_count  <- 0L
  all_agree       <- rep(TRUE, n_players)

  while (!all(all_agree == agree_status)) {
    p <- first_false(agree_status)
    res <- get_player_move(game, p, strategy, agree_status)
    iteration_count <- iteration_count + 1L

    strategy     <- res$strategy
    agree_status <- res$agree_status

    if (res$is_new) {
      used_strategies <- rbind(used_strategies, strategy)

      # Count the number of movements
      movements_count <- movements_count + 1L

      # Break if loop detected
      if (has_dup_rows(used_strategies)) {
        return(c("Equilibrium not found", iteration_count, movements_count))
      }
    }
  }

  c("Equilibrium found", iteration_count, movements_count)
}


#' Run multiple games and collect results
#'
#' @param n_games Integer. Number of games to simulate.
#' @param n_players Integer. Number of players per game.
#' @return Data.frame with columns:
#'   * `status`: Simulation outcome for each game.
#'   * `iterations`: Number of iterations taken in each simulation.
#' @examples
#' run_many_games(10, 4)
#' @export
run_many_games <- function(n_games, n_players) {
  mat <- t(sapply(
    seq_len(n_games),
    function(i) {
      g   <- set_game(n_players)
      play_game(n_players, g)
    }
  ))
  df <- as.data.frame(mat, stringsAsFactors = FALSE)
  names(df) <- c("status", "iterations")

  # order the data frame by status (alphabetically)
  df <- df[order(df$status), ]
  df$iterations <- as.numeric(df$iterations)
  df
}


#' Summarize and plot game results with iterations and movements
#'
#' Overlaid barplots of integer counts for both iterations and movements,
#' using the original color palette, with a cleaned-up x-axis showing
#' only “pretty” integer ticks. Adds a legend and displays the total number
#' of players as an outer title.
#'
#' @param res_mat Data.frame or matrix with columns `status`, `iterations`, and `movements`.
#' @param n_players Integer. Number of players used in the simulations.
#' @return Invisibly returns `NULL`; prints overlaid barplots.
#' @examples
#' res <- run_many_games(100, 4)
#' summary_game_results(res, 4)
#' @export
summary_game_results <- function(res_mat, n_players) {
  df <- as.data.frame(res_mat, stringsAsFactors = FALSE)
  names(df) <- c("status", "iterations", "movements")
  df$iterations <- as.integer(df$iterations)
  df$movements  <- as.integer(df$movements)

  sts      <- unique(df$status)
  counts   <- table(df$status)
  pct      <- round((counts / sum(counts)) * 100, 1)
  base_cols <- c("steelblue", "green4")[seq_along(sts)]
  mov_col   <- "tomato"

  oldpar <- par(no.readonly = TRUE)
  on.exit(par(oldpar), add = TRUE)
  par(
    mfrow = c(1, length(sts)),
    mar   = c(4, 4, 3, 1),
    oma   = c(0, 0, 3, 0)
  )

  for (i in seq_along(sts)) {
    st  <- sts[i]
    its <- df$iterations[df$status == st]
    mov <- df$movements[df$status == st]
    n   <- counts[st]
    p   <- pct[st]

    cnts_its <- table(its)
    cnts_mov <- table(mov)
    vals     <- sort(unique(c(as.integer(names(cnts_its)), as.integer(names(cnts_mov)))))

    # Plot iterations (no x-labels yet), capture bar midpoints
    mids <- barplot(
      cnts_its[as.character(vals)],
      names.arg = NA,
      col       = adjustcolor(base_cols[i], alpha.f = 0.8),
      border    = NA,
      space     = 0,
      ylim      = c(0, max(cnts_its, cnts_mov)),
      main      = paste0(st, " (n=", n, ", ", p, "%)"),
      xlab      = "Value",
      ylab      = "Frequency"
    )
    # Overlay movements
    barplot(
      cnts_mov[as.character(vals)],
      names.arg = NA,
      col       = adjustcolor(mov_col, alpha.f = 0.8),
      border    = NA,
      space     = 0,
      add       = TRUE
    )

    # Add a clean, integer-based axis
    pretty_vals <- pretty(vals)
    pretty_vals <- pretty_vals[pretty_vals %in% vals]
    axis(1, at = mids[match(pretty_vals, vals)], labels = pretty_vals)

    legend(
      "topright",
      legend = c("Iterations", "Movements"),
      fill   = c(adjustcolor(base_cols[i], alpha.f = 0.8), adjustcolor(mov_col, alpha.f = 0.8)),
      bty    = "n"
    )
  }

  mtext(
    text  = paste("Number of players:", n_players),
    side  = 3,
    outer = TRUE,
    cex   = 1.5,
    line  = 1
  )
}
