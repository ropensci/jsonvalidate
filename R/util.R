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
