##' Create a validator that can validate multiple json files.
##'
##' @section Validation Engines:
##'
##' We support two different json validation engines, `imjv`
##'   ("is-my-json-valid") and `ajv` ("Another JSON
##'   Validator"). `imjv` was the original validator included in
##'   the package and remains the default for reasons of backward
##'   compatibility. However, users are encouraged to migrate to
##'   `ajv` as with it we support many more features, including
##'   nested schemas that span multiple files, meta schema versions
##'   later than draft-04, validating using a subschema, and
##'   validating a subset of an input data object.
##'
##' If your schema uses these features we will print a message to
##'   screen indicating that you should update when running
##'   interactively. We do not use a warning here as this will be
##'   disruptive to users. You can disable the message by setting the
##'   option `jsonvalidate.no_note_imjv` to `TRUE`. Consider using
##'   [withr::with_options()] (or simply [suppressMessages()]) to
##'   scope this option if you want to quieten it within code you do
##'   not control.  Alternatively, setting the option
##'   `jsonvalidate.no_note_imjv` to `FALSE` will print the message
##'   even noninteractively.
##'
##' Updating the engine should be simply a case of adding `{engine
##'   = "ajv"` to your `json_validator` or `json_validate`
##'   calls, but you may see some issues when doing so.
##'
##' * Your json now fails validation: We've seen this where schemas
##'   spanned several files and are silently ignored. By including
##'   these, your data may now fail validation and you will need to
##'   either fix the data or the schema.
##'
##' * Your code depended on the exact payload returned by `imjv`: If
##'   you are inspecting the error result and checking numbers of
##'   errors, or even the columns used to describe the errors, you
##'   will likely need to update your code to accommodate the slightly
##'   different format of `ajv`
##'
##' * Your schema is simply invalid: If you reference an invalid
##'   metaschema for example, jsonvalidate will fail
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
##'   `engine = "ajv"`.
##'
##' @param strict Set whether the schema should be parsed strictly or not.
##'   If in strict mode schemas will error to "prevent any unexpected
##'   behaviours or silently ignored mistakes in user schema". For example
##'   it will error if encounters unknown formats or unknown keywords. See
##'   https://ajv.js.org/strict-mode.html for details. Only available in
##'   `engine = "ajv"`.
##'
##' @section Using multiple files:
##'
##' Multiple files are supported.  You can have a schema that
##'   references a file `child.json` using `{"$ref": "child.json"}` -
##'   in this case if `child.json` includes an `id` or `$id` element
##'   it will be silently dropped and the filename used to reference
##'   the schema will be used as the schema id.
##'
##' The support is currently quite limited - it will not (yet) read
##'   sub-child schemas relative to child schema `$id` url, and
##'   does not support reading from URLs (only local files are
##'   supported).
##'
##' @export
##' @example man-roxygen/example-json_validator.R
json_validator <- function(schema, engine = "imjv", reference = NULL,
                           strict = FALSE) {
  v8 <- jsonvalidate_js()
  schema <- read_schema(schema, v8)

  switch(engine,
         imjv = json_validator_imjv(schema, v8, reference),
         ajv = json_validator_ajv(schema, v8, reference, strict),
         stop(sprintf("Unknown engine '%s'", engine)))
}


##' Validate a single json against a schema.  This is a convenience
##' wrapper around `json_validator(schema)(json)`.  See
##' [jsonvalidate::json_validator()] for further details.
##'
##' @title Validate a json file
##'
##' @inheritParams json_validator
##'
##' @param json Contents of a json object, or a filename containing
##'   one.
##'
##' @param verbose Be verbose?  If `TRUE`, then an attribute
##'   "errors" will list validation failures as a data.frame
##'
##' @param greedy Continue after the first error?
##'
##' @param error Throw an error on parse failure?  If `TRUE`,
##'   then the function returns `NULL` on success (i.e., call
##'   only for the side-effect of an error on failure, like
##'   `stopifnot`).
##'
##' @param query A string indicating a component of the data to
##'   validate the schema against.  Eventually this may support full
##'   [jsonpath](https://www.npmjs.com/package/jsonpath) syntax, but
##'   for now this must be the name of an element within `json`.  See
##'   the examples for more details.
##'
##' @export
##' @example man-roxygen/example-json_validate.R
json_validate <- function(json, schema, verbose = FALSE, greedy = FALSE,
                          error = FALSE, engine = "imjv", reference = NULL,
                          query = NULL, strict = FALSE) {
  validator <- json_validator(schema, engine, reference = reference,
                              strict = strict)
  validator(json, verbose, greedy, error, query)
}


json_validator_imjv <- function(schema, v8, reference) {
  meta_schema_version <- schema$meta_schema_version %||% "draft-04"

  if (!is.null(reference)) {
    ## This one has to be an error; it has never worked and makes no
    ## sense.
    stop("subschema validation only supported with engine 'ajv'")
  }

  if (meta_schema_version != "draft-04") {
    ## We detect the version, so let the user know they are not really
    ## getting what they're asking for
    note_imjv(paste(
      "meta schema version other than 'draft-04' is only supported with",
      sprintf("engine 'ajv' (requested: '%s')", meta_schema_version),
      "- falling back to use 'draft-04'"))
    meta_schema_version <- "draft-04"
  }

  if (length(schema$dependencies) > 0L) {
    ## We've found references, but can't support them. Let the user
    ## know.
    note_imjv("Schema references are only supported with engine 'ajv'")
  }

  v8$call("imjv_create", meta_schema_version, V8::JS(schema$schema))

  ret <- function(json, verbose = FALSE, greedy = FALSE, error = FALSE,
                  query = NULL) {
    if (!is.null(query)) {
      stop("Queries are only supported with engine 'ajv'")
    }
    if (error) {
      verbose <- TRUE
    }
    res <- v8$call("imjv_call", V8::JS(get_string(json)),
                   verbose, greedy)
    validation_result(res, error, verbose)
  }

  ret
}


json_validator_ajv <- function(schema, v8, reference, strict) {
  meta_schema_version <- schema$meta_schema_version %||% "draft-07"

  versions_legal <- c("draft-04", "draft-06", "draft-07", "draft/2019-09",
                      "draft/2020-12")
  if (!(meta_schema_version %in% versions_legal)) {
    stop(sprintf("Unknown meta schema version '%s'", meta_schema_version))
  }

  if (is.null(reference)) {
    reference <- V8::JS("null")
  }
  if (is.null(schema$filename)) {
    schema$filename <- V8::JS("null")
  }
  dependencies <- V8::JS(schema$dependencies %||% "null")
  v8$call("ajv_create", meta_schema_version, strict,
          V8::JS(schema$schema), schema$filename, dependencies, reference)

  ret <- function(json, verbose = FALSE, greedy = FALSE, error = FALSE,
                  query = NULL) {
    res <- v8$call("ajv_call", V8::JS(get_string(json)),
                   error || verbose, query_validate(query))
    validation_result(res, error, verbose)
  }

  ret
}


validation_result <- function(res, error, verbose) {
  success <- res$success

  if (!success) {
    if (error) {
      stop(validation_error(res))
    }
    if (verbose) {
      ## In ajv version < 8 errors had dataPath property. This has
      ## been renamed to instancePath in v8 +. Keep dataPath for
      ## backwards compatibility to support dccvalidator
      res$errors$dataPath <- res$errors$instancePath
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
                            errors$instancePath,
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


query_validate <- function(query) {
  if (is.null(query)) {
    return(V8::JS("null"))
  }
  ## To ensure backward-compatibility, rule out all but the most
  ## simple queries for now
  if (grepl("[/@.\\[$\"\'|*?()]", query)) {
    stop("Full json-path support is not implemented")
  }
  query
}
