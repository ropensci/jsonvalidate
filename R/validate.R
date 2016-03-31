##' Create a validator that can validate multiple json files.
##'
##' @title Create a json validator
##' @param schema Contents of the json schema, or a filename
##'   containing a schema.
##' @export
json_validator <- function(schema) {
  name <- basename(tempfile("jv_"))
  env$ct$eval(sprintf("%s = validator(%s)", name, get_string(schema)))
  ret <- function(json) {
    env$ct$call(name, V8::JS(get_string(json)))
  }
  attr(ret, "name") <- name
  ret
}

##' Validate a single json against a schema.  This is a convenience
##' wrapper around \code{json_validator(schema)(json)}
##' @title Validate a json file
##' @inheritParams json_validator
##' @param json Contents of a json object, or a filename containing one.
##' @export
json_validate <- function(json, schema) {
  tmp <- json_validator(schema)
  on.exit(env$ct$eval(sprintf("delete %s", attr(tmp, "name"))))
  tmp(json)
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
  env$ct <- V8::new_context()
  env$ct$source(system.file("is-my-json-valid.js", package=.packageName))
}
