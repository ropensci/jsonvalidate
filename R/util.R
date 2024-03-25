get_string <- function(x, what = deparse(substitute(x))) {
  if (length(x) == 0L) {
    stop(sprintf("zero length input for %s", what))
  }
  if (!is.character(x)) {
    stop(sprintf("Expected a character vector for %s", what))
  }

  if (refers_to_file(x)) {
    x <- paste(readLines(x, warn = FALSE), collapse = "\n")
  } else if (length(x) > 1L) {
    x <- paste(x, collapse = "\n")
  }

  x
}


refers_to_file <- function(x) {
  ## good reasons not to be a file:
  if (length(x) != 1 || inherits(x, "json") || grepl("{", x, fixed = TRUE)) {
    return(FALSE)
  }
  file.exists(x)
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


note_imjv <- function(msg, is_interactive = interactive()) {
  ## no_note_imjv  interactive => outcome
  ##         NULL         TRUE    message
  ##         NULL        FALSE    silent
  ##        FALSE        <any>    message
  ##         TRUE        <any>    silent
  no_note_imjv <- getOption("jsonvalidate.no_note_imjv")

  if (is.null(no_note_imjv)) {
    show <- is_interactive
  } else {
    show <- !no_note_imjv
  }
  if (show) {
    message(msg)
  }
}

path_includes_dir <- function(x) {
  !is.null(x) && basename(x) != x
}

is_absolute_path <- function(path) {
  grepl("^(/|[A-Za-z]:)", path)
}
