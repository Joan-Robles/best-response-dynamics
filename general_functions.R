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


find_extra_row <- function(big_matrix, small_matrix) {
  # Collapse each row to a single string key
  big_keys   <- do.call(paste, c(as.data.frame(big_matrix), sep = "\r"))
  small_keys <- do.call(paste, c(as.data.frame(small_matrix), sep = "\r"))
  
  # Find the first key in big not in small
  idx <- which(!big_keys %in% small_keys)[1L]
  if (is.na(idx)) {
    return(NULL)  # no extra row found
  }
  
  # Return that row
  big_matrix[idx, , drop = FALSE]
}


# Fast Cartesian product of {0,1} repeated n times as a matrix of 0/1
cartesian_binary <- function(n) {
  # total number of rows
  N <- 2^n
  # integer codes 0:(2^n-1)
  codes <- 0:(N - 1)
  # for each bit position k (0 = LSB, n-1 = MSB), extract that bit
  mat <- vapply(
    0:(n-1),
    function(k) bitwAnd(bitwShiftR(codes, k), 1L),
    integer(N)
  )
  # reorder columns so that column 1 is the MSB (bit n-1)
  mat[, n:1, drop = FALSE]
}
