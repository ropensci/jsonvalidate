get_string <- function(x, what = deparse(substitute(x))) {
  if (length(x) == 0L) {
    stop(sprintf("zero length input for %s", what))
  }
  if (!is.character(x)) {
    stop(sprintf("Expected a character vector for %s", what))
  }

  ## TODO: this will get looked at in the next PR as we need to force
  ## filenames better; it's not possible with this approach to error
  ## if a file is missed through a typo.
  if (length(x) == 1 && file.exists(x)) {
    x <- paste(readLines(x), collapse = "\n")
  } else if (length(x) > 1L) {
    x <- paste(x, collapse = "\n")
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



with_dir <- function(path, code) {
  owd <- setwd(path)
  on.exit(setwd(owd))
  force(code)
}


vlapply <- function(X, FUN, ...) {
  vapply(X, FUN, logical(1), ...)
}


vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)

}


squote <- function(x) {
  sprintf("'%s'", x)
}


set_names <- function(x, nms) {
  names(x) <- nms
  x
}
