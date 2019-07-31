get_string <- function(x) {
  if (length(x) == 0L) {
    stop("zero length input")
  } else if (!is.character(x)) {
    stop("Expected a character vector")
  } else if (length(x) > 1L) {
    x <- paste(x, collapse = "\n")
  } else if (file.exists(x) && !inherits(x, "AsIs")) {
    x <- paste(readLines(x), collapse = "\n")
  }
  x
}


## An alternative here would be to drag in ids which has a nice
## random_id function.  This approach here is at least safe to seed
## setting
random_id <- function() {
  basename(tempfile(""))
}


`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}
