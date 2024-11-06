##' Safe serialisation of json with unboxing guided by the schema.
##'
##' When using [jsonlite::toJSON] we are forced to deal with the
##' differences between R's types and those available in JSON. In
##' particular:
##'
##' * R has no scalar types so it is not clear if `1` should be
##'   serialised as a number or a vector of length 1; `jsonlite`
##'   provides support for "automatically unboxing" such values
##'   (assuming that length-1 vectors are scalars) or never unboxing
##'   them unless asked to using [jsonlite::unbox]
##' * JSON has no date/time values and there are many possible string
##'   representations.
##' * JSON has no [data.frame] or [matrix] type and there are several
##'   ways of representing these in JSON, all equally valid (e.g., row-wise,
##'   column-wise or as an array of objects).
##' * The handling of `NULL` and missing values (`NA`, `NaN`) are different
##' * We need to chose the number of digits to write numbers out at,
##'   balancing precision and storage.
##'
##' These issues are somewhat lessened when we have a schema because
##' we know what our target type looks like.  This function attempts
##' to use the schema to guide serialisation of json safely.  Currently
##' it only supports detecting the appropriate treatment of length-1
##' vectors, but we will expand functionality over time.
##'
##' For a user, this function provides an argument-free replacement
##' for `jsonlite::toJSON`, accepting an R object and returning a
##' string with the JSON representation of the object. Internally the
##' algorithm is:
##'
##' 1. serialise the object with [jsonlite::toJSON], with
##'    `auto_unbox = FALSE` so that length-1 vectors are serialised as a
##'    length-1 arrays.
##' 2. operating entirely within JavaScript, deserialise the object
##'    with `JSON.parse`, traverse the object and its schema
##'    simultaneously looking for length-1 arrays where the schema
##'    says there should be scalar value and unboxing these, and
##'    re-serialise with `JSON.stringify`
##'
##' There are several limitations to our current approach, and not all
##' unboxable values will be found - at the moment we know that
##' schemas contained within a `oneOf` block (or similar) will not be
##' recursed into.
##'
##' # Warning
##'
##' Direct use of this function will be slow!  If you are going to
##'   serialise more than one or two objects with a single schema, you
##'   should use the `serialise` method of a
##'   [jsonvalidate::json_schema] object which you create once and pass around.
##'
##' @title Safe JSON serialisation
##'
##' @param object An object to be serialised
##'
##' @param schema A schema (string or path to a string, suitable to be
##'   passed through to [jsonvalidate::json_validator] or a validator
##'   object itself.
##'
##' @param engine The engine to use. Only ajv is supported, and trying
##'   to use `imjv` will throw an error.
##'
##' @inheritParams json_validate
##'
##' @return A string, representing `object` in JSON format. As for
##'   `jsonlite::toJSON` we set the class attribute to be `json` to
##'   mark it as serialised json.
##'
##' @export
##' @example man-roxygen/example-json_serialise.R
json_serialise <- function(object, schema, engine = "ajv", reference = NULL,
                           strict = FALSE) {
  obj <- json_schema$new(schema, engine, reference, strict)
  obj$serialise(object)
}


json_serialise_imjv <- function(v8, object) {
  stop("json_serialise is only supported with engine 'ajv'")
}


json_serialise_ajv <- function(v8, object) {
  str <- jsonlite::toJSON(object, auto_unbox = FALSE)
  ret <- v8$call("safeSerialise", str)
  class(ret) <- "json"
  ret
}
