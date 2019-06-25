##' Create a validator that can validate multiple json files.
##'
##' @title Create a json validator
##'
##' @param schema Contents of the json schema, or a filename
##'   containing a schema.
##'
##'
##' @param engine Specify the validation engine to use.  Options are
##'   "imjv" (the default; which uses "is-my-json-valid") and "ajv"
##'   (Another JSON Schema Validator).  The latter supports more
##'   recent json schema features.
##'
##' @export
##' @example man-roxygen/example-json_validator.R
json_validator <- function(schema, engine = "imjv") {
  schema <- get_string(schema)
  switch(engine,
         imjv = json_validator_imjv(schema),
         ajv = json_validator_ajv(schema),
         stop(sprintf("Unknown engine '%s'", engine)))
}


json_validator_imjv <- function(schema) {
  name <- basename(tempfile("jv_"))
  env$ct$eval(sprintf("%s = imjv(%s)", name, schema))
  ret <- function(json, verbose = FALSE, greedy = FALSE, error = FALSE) {
    if (error) {
      verbose <- TRUE
    }
    res <- env$ct$call(name, V8::JS(get_string(json)),
                       list(verbose = verbose),
                       list(greedy = greedy))
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
                               collapse = "\n"))
          stop(msg, call. = FALSE)
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


json_validator_ajv <- function(schema) {
  name <- basename(tempfile("jv_"))

  # determine meta-schema version
  meta_schema <- env$ct$eval(sprintf("get_meta_schema(%s)", schema))
  meta_schema_version <- get_meta_schema_version(meta_schema)

  # if not recognized, use "draft-07"
  if (is.null(meta_schema_version)) {
    meta_schema_version <- "draft-07"
  }

  # determine the name of the generator-function to call
  ajv_name <- switch(
    meta_schema_version,
    `draft-04` = "ajv_04",
    `draft-06` = "ajv",
    `draft-07` = "ajv",
  )

  # call the generator to create the validator
  env$ct$eval(
    sprintf("%s = %s.compile(%s)", name, ajv_name, schema)
  )

  ret <- function(json, verbose = FALSE, greedy = FALSE, error = FALSE) {
    ## NOTE: with the ajv validator, because the "greedy" switch needs
    ## to go into the schema compilation step it's not a great fit
    ## here.  But the primary effect is that
    if (error) {
      verbose <- TRUE
    }
    res <- env$ct$call(name, V8::JS(get_string(json)))

    if (verbose) {
      errors <- env$ct$get(paste0(name, ".errors"))
      if (error) {
        if (is.null(errors)) {
          return(NULL)
        } else {
          n <- nrow(errors)
          msg <- sprintf("%s %s validating json:\n%s",
                         n, ngettext(n, "error", "errors"),
                         paste(sprintf("\t- %s (%s): %s",
                                       errors$dataPath,
                                       errors$schemaPath,
                                       errors$message),
                               collapse = "\n"))
          ret <- structure(
            list(message = msg, errors = errors),
            class = c("validation_error", "error", "condition"))
          stop(ret)
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
##'
##' @title Validate a json file
##'
##' @inheritParams json_validator
##'
##' @param json Contents of a json object, or a filename containing
##'   one.
##'
##' @param verbose Be verbose?  If \code{TRUE}, then an attribute
##'   "errors" will list validation failures as a data.frame
##'
##' @param greedy Continue after the first error?
##'
##' @param error Throw an error on parse failure?  If \code{TRUE},
##'   then the function returns \code{NULL} on success (i.e., call
##'   only for the side-effect of an error on failure, like
##'   \code{stopifnot}).
##' @export
##' @example man-roxygen/example-json_validate.R
json_validate <- function(json, schema, verbose = FALSE, greedy = FALSE,
                          error = FALSE, engine = "imjv") {
  tmp <- json_validator(schema, engine)
  on.exit(env$ct$eval(sprintf("delete %s", attr(tmp, "name"))))
  tmp(json, verbose, greedy, error)
}


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

# internal function to determine version given a string
get_meta_schema_version <- function(x) {

  regex <- "^http://json-schema.org/(draft-\\d{2})/schema#$"
  version <- gsub(regex, "\\1", x)

  versions_legal <- c("draft-04", "draft-06", "draft-07")
  if (!version %in% versions_legal) {
    return(NULL)
  }

  version
}

env <- new.env(parent = emptyenv())


.onLoad <- function(libname, pkgname) {
  env$ct <- V8::v8()
  env$ct$source(system.file("bundle.js", package = "jsonvalidate"))
}
