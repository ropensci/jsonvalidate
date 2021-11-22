##' Safe serialisation of json with unboxing guided by the schema.
##'
##' When using [jsonlite::toJSON] we are forced to deal with the
##' differences between R's types and those available in JSON. In
##' particular:
##'
##' * R has no scalar types so it is not clear if `1` should be
##'   serialised as a number or a vector of length 1; jsonlite
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
##' to use the schema to guide serialsation of json safely.  Currently
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
##' @title Safe JSON serialisation
##'
##' @param x An object to be serialised
##'
##' @param schema A schema (string or path to a string, suitable to be
##'   passed through to [jsonvalidate::json_validator] or a validator
##'   object itself.
##'
##' @return A string, representing `x` in JSON format
##' @export
##' @examples
##' # TODO
json_serialise <- function(x, schema) {
  if (is.character(schema)) {
    validator <- json_validator(schema, engine = "ajv")
    v8 <- environment(validator)$v8
  } else if (inherits(schema, "function")) {
    v8 <- environment(schema)$v8
  } else {
    stop("Invalid input for 'schema'")
  }

  str <- jsonlite::toJSON(x, auto_unbox = FALSE)

  v8$call("safeSerialise", str)
}
