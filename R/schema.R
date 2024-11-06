##' @name json_schema
##' @rdname json_schema
##' @title Interact with JSON schemas
##'
##' @description Interact with JSON schemas, using them to validate
##'   json strings or serialise objects to JSON safely.
##'
##' This interface supersedes [jsonvalidate::json_schema] and changes
##'   some default arguments.  While the old interface is not going
##'   away any time soon, users are encouraged to switch to this
##'   interface, which is what we will develop in the future.
##'
##' @example man-roxygen/example-json_serialise.R
NULL

## Workaround for https://github.com/r-lib/roxygen2/issues/1158

##' @rdname json_schema
##' @export
json_schema <- R6::R6Class(
  "json_schema",
  cloneable = FALSE,

  private = list(
    v8 = NULL,
    do_validate = NULL,
    do_serialise = NULL),

  public = list(
    ##' @field schema The parsed schema, cannot be rebound
    schema = NULL,

    ##' @field engine The name of the schema validation engine
    engine = NULL,

    ##' @description Create a new `json_schema` object.
    ##'
    ##' @param schema Contents of the json schema, or a filename
    ##'   containing a schema.
    ##'
    ##' @param engine Specify the validation engine to use.  Options are
    ##'   "ajv" (the default; "Another JSON Schema Validator") or "imjv"
    ##'  ("is-my-json-valid", the default everywhere in versions prior
    ##'  to 1.4.0, and the default for [jsonvalidate::json_validator].
    ##'  *Use of `ajv` is strongly recommended for all new code*.
    ##'
    ##' @param reference Reference within schema to use for validating
    ##'   against a sub-schema instead of the full schema passed in.
    ##'   For example if the schema has a 'definitions' list including a
    ##'   definition for a 'Hello' object, one could pass
    ##'   "#/definitions/Hello" and the validator would check that the json
    ##'   is a valid "Hello" object. Only available if `engine = "ajv"`.
    ##'
    ##' @param strict Set whether the schema should be parsed strictly or not.
    ##'   If in strict mode schemas will error to "prevent any unexpected
    ##'   behaviours or silently ignored mistakes in user schema". For example
    ##'   it will error if encounters unknown formats or unknown keywords. See
    ##'   https://ajv.js.org/strict-mode.html for details. Only available in
    ##'   `engine = "ajv"` and silently ignored for "imjv".
    initialize = function(schema, engine = "ajv", reference = NULL,
                          strict = FALSE) {
      v8 <- jsonvalidate_js()
      schema <- read_schema(schema, v8)
      if (engine == "imjv") {
        private$v8 <- json_schema_imjv(schema, v8, reference)
        private$do_validate <- json_validate_imjv
        private$do_serialise <- json_serialise_imjv
      } else if (engine == "ajv") {
        private$v8 <- json_schema_ajv(schema, v8, reference, strict)
        private$do_validate <- json_validate_ajv
        private$do_serialise <- json_serialise_ajv
      } else {
        stop(sprintf("Unknown engine '%s'", engine))
      }

      self$engine <- engine
      self$schema <- schema
      lockBinding("schema", self)
      lockBinding("engine", self)
    },

    ##' Validate a json string against a schema.
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
    validate = function(json, verbose = FALSE, greedy = FALSE, error = FALSE,
                        query = NULL) {
      private$do_validate(private$v8, json, verbose, greedy, error, query)
    },

    ##' Serialise an R object to JSON with unboxing guided by the schema.
    ##' See [jsonvalidate::json_serialise] for details on the problem and
    ##' the algorithm.
    ##'
    ##' @param object An R object to serialise
    serialise = function(object) {
      private$do_serialise(private$v8, object)
    }
  ))


json_schema_imjv <- function(schema, v8, reference) {
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

  v8
}


json_schema_ajv <- function(schema, v8, reference, strict) {
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

  v8
}
