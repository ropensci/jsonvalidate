##' Create a validator that can validate multiple json files.
##'
##' @title Create a json validator
##' @param schema Contents of the json schema, or a filename
##'   containing a schema.
##' @export
json_validator <- function(schema) {
  name <- basename(tempfile("jv_"))
  env$ct$eval(sprintf("%s = validator(%s)", name, get_string(schema)))
  ret <- function(json, verbose=FALSE, greedy=FALSE, error=FALSE) {
    if (error) {
      verbose <- TRUE
    }
    res <- env$ct$call(name, V8::JS(get_string(json)),
                       list(verbose=verbose),
                       list(greedy=greedy))
    if (verbose) {
      errors <- env$ct$get(paste0(name, ".errors"))
      if (error) {
        if (is.null(errors)) {
          return(NULL)
        } else {
          n <- nrow(errors)
          msg <- sprintf("%s %s validating json:\n%s",
                         n, ngettext(n, "error", "errors"),
                         paste(sprintf("\t- %s: %s", errors[[1]], errors[[2]]),
                               collapse="\n"))
          stop(msg, call.=FALSE)
        }
      } else {
        attr(res, "errors") <- errors
      }
    }
    res
  }
  attr(ret, "name") <- name
  ret
}

##' Validate a single json against a schema.  This is a convenience
##' wrapper around \code{json_validator(schema)(json)}
##' @title Validate a json file
##' @inheritParams json_validator
##' @param json Contents of a json object, or a filename containing
##'   one.
##' @param verbose Be verbose?  If \code{TRUE}, then an attribute
##'   "errors" will list validation failures as a data.frame
##' @param greedy Continue after the first error?
##' @param error Throw an error on parse failure?  If \code{TRUE},
##'   then the function returns \code{NULL} on success (i.e., call
##'   only for the side-effect of an error on failure, like
##'   \code{stopifnot}).
##' @export
json_validate <- function(json, schema, verbose=FALSE, greedy=FALSE,
                          error=FALSE) {
  tmp <- json_validator(schema)
  on.exit(env$ct$eval(sprintf("delete %s", attr(tmp, "name"))))
  tmp(json, verbose, greedy, error)
}

get_string <- function(x) {
  if (length(x) == 0L) {
    stop("zero length input")
  } else if (!is.character(x)) {
    stop("Expected a character vector")
  } else if (length(x) > 1L) {
    x <- paste(x, collapse="\n")
  } else if (file.exists(x) && !inherits(x, "AsIs")) {
    x <- paste(readLines(x), collapse="\n")
  }
  x
}

env <- new.env(parent=emptyenv())
.onLoad <- function(libname, pkgname) {
  env$ct <- V8::v8()
  env$ct$source(system.file("is-my-json-valid.js", package=.packageName))
}
