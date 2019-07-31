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
##' @param reference Reference within schema to use for validating against a 
##'   sub-schema instead of the full schema passed in. For example
##'   if the schema has a 'definitions' list including a definition for a 
##'   'Hello' object, one could pass "#/definitions/Hello" and the validator
##'   would check that the json is a valid "Hello" object. Only available if 
##'   \code{engine = 'ajv'}.
##'   
##' @export
##' @example man-roxygen/example-json_validator.R
json_validator <- function(schema, engine = "imjv", reference = NULL) {
  if (!is.null(reference) && engine != 'ajv') {
    stop("reference option only permissible with engine 'ajv'")
  }
  schema <- read_schema(schema)
  v8 <- env$ct
  switch(engine,
         imjv = json_validator_imjv(schema, v8),
         ajv = json_validator_ajv(schema, v8, reference),
         stop(sprintf("Unknown engine '%s'", engine)))
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
##'   
##' @param reference Reference within schema to use for validating against a 
##'   sub-schema instead of the full schema passed in. For example
##'   if the schema has a 'definitions' list including a definition for a 
##'   'Hello' object, one could pass "#/definitions/Hello" and the validator
##'   would check that the json is a valid "Hello" object. Only available if 
##'   \code{engine = 'ajv'}.
##' 
##' @export
##' @example man-roxygen/example-json_validate.R
json_validate <- function(json, schema, verbose = FALSE, greedy = FALSE,
                          error = FALSE, engine = "imjv", reference = NULL) {
  tmp <- json_validator(schema, engine, reference = reference)
  tmp(json, verbose, greedy, error)
}


json_validator_imjv <- function(schema, v8) {
  name <- random_id()
  meta_schema_version <- schema$meta_schema_version %||% "draft-04"

  v8$call("imjv_create", name, meta_schema_version, V8::JS(schema$schema))

  ret <- function(json, verbose = FALSE, greedy = FALSE, error = FALSE) {
    if (error) {
      verbose <- TRUE
    }
    res <- v8$call("imjv_call", name, V8::JS(get_string(json)),
                   verbose, greedy)
    validation_result(res, error, verbose)
  }

  reg.finalizer(environment(ret), cleanup("imjv", name, v8))

  ret
}


json_validator_ajv <- function(schema, v8, reference) {
  name <- random_id()
  meta_schema_version <- schema$meta_schema_version %||% "draft-07"

  if (is.null(reference)) {
    reference <- V8::JS("null")
  }

  v8$call("ajv_create", name, meta_schema_version, V8::JS(schema$schema),
          reference)

  ret <- function(json, verbose = FALSE, greedy = FALSE, error = FALSE) {
    res <- v8$call("ajv_call", name, V8::JS(get_string(json)),
                   error || verbose)
    validation_result(res, error, verbose)
  }

  reg.finalizer(environment(ret), cleanup("imjv", name, v8))

  ret
}



## internal function to determine version given a string
get_meta_schema_version <- function(x) {
  regex <- "^http://json-schema.org/(draft-\\d{2})/schema#$"
  version <- gsub(regex, "\\1", x)

  versions_legal <- c("draft-04", "draft-06", "draft-07")
  if (!version %in% versions_legal) {
    return(NULL)
  }

  version
}


cleanup <- function(type, name, v8) {
  force(type)
  force(name)
  force(v8)
  function(e) {
    v8$call("cleanup", type, name)
  }
}


validation_result <- function(res, error, verbose) {
  success <- res$success

  if (!success) {
    if (error) {
      stop(validation_error(res))
    }
    if (verbose) {
      attr(success, "errors") <- res$errors
    }
  }

  success
}


validation_error <- function(res) {
  errors <- res$errors
  n <- nrow(errors)
  if (res$engine == "ajv") {
    detail <- paste(sprintf("\t- %s (%s): %s",
                            errors$dataPath,
                            errors$schemaPath,
                            errors$message),
                    collapse = "\n")
  } else {
    detail <- paste(sprintf("\t- %s: %s",
                            errors[[1]],
                            errors[[2]]),
                    collapse = "\n")
  }
  msg <- sprintf("%s %s validating json:\n%s",
                 n, ngettext(n, "error", "errors"), detail)
  structure(
    list(message = msg, errors = errors),
    class = c("validation_error", "error", "condition"))
}
