json_schema <- R6::R6Class(
  "json_schema",

  private = list(
    v8 = NULL,
    do_validate = NULL,
    do_serialise = NULL),

  public = list(
    schema = NULL,
    engine = NULL,

    initialize = function(schema, engine, reference = NULL, strict = FALSE) {
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

      lockBinding("schema", self)
      lockBinding("engine", self)
    },

    validate = function(json, verbose = FALSE, greedy = FALSE, error = FALSE,
                        query = NULL) {
      private$do_validate(private$v8, json, verbose, greedy, error, query)
    },

    serialise = function(x) {
      private$do_serialise(private$v8, x)
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
