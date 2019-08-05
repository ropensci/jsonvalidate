##' Create a validator that can validate multiple json files.
##'
##' @title Create a json validator
##'
##' @param schema Contents of the json schema, or a filename
##'   containing a schema.
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
  v8 <- env$ct
  schema <- read_schema(schema, v8)
  switch(engine,
         imjv = json_validator_imjv(schema, v8, reference),
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
##' @export
##' @example man-roxygen/example-json_validate.R
json_validate <- function(json, schema, verbose = FALSE, greedy = FALSE,
                          error = FALSE, engine = "imjv", reference = NULL) {
  tmp <- json_validator(schema, engine, reference = reference)
  tmp(json, verbose, greedy, error)
}


json_validator_imjv <- function(schema, v8, reference) {
  name <- random_id()
  meta_schema_version <- schema$meta_schema_version %||% "draft-04"

  if (!is.null(reference)) {
    stop("subschema validation only supported with engine 'ajv'")
  }

  if (meta_schema_version != "draft-04") {
    stop(sprintf(
      "meta schema version '%s' is only supported with engine 'ajv'",
      meta_schema_version))
  }

  if (length(schema$dependencies) > 0L) {
    stop("Schema references are only supported with engine 'ajv'")
  }

  v8$call("imjv_create", name, meta_schema_version, V8::JS(schema$schema))

  ret <- function(json, verbose = FALSE, greedy = FALSE, error = FALSE) {
    if (error) {
      verbose <- TRUE
    }
    res <- v8$call("imjv_call", name, V8::JS(get_string(json)),
                   verbose, greedy)
    validation_result(res, error, verbose)
  }

  reg.finalizer(environment(ret), validator_delete("imjv", name, v8))

  ret
}


json_validator_ajv <- function(schema, v8, reference) {
  name <- random_id()
  meta_schema_version <- schema$meta_schema_version %||% "draft-07"

  if (is.null(reference)) {
    reference <- V8::JS("null")
  }
  dependencies <- V8::JS(schema$dependencies %||% "null")
  v8$call("ajv_create", name, meta_schema_version, V8::JS(schema$schema),
          dependencies, reference)

  ret <- function(json, verbose = FALSE, greedy = FALSE, error = FALSE) {
    res <- v8$call("ajv_call", name, V8::JS(get_string(json)),
                   error || verbose)
    validation_result(res, error, verbose)
  }

  reg.finalizer(environment(ret), validator_delete("imjv", name, v8))

  ret
}


validator_delete <- function(type, name, v8) {
  force(type)
  force(name)
  force(v8)
  function(e) {
    v8$call("validator_delete", type, name)
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
