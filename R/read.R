read_schema <- function(x) {
  schema <- get_string(x)

  meta_schema <- env$ct$eval(sprintf("get_meta_schema_version(%s)", schema))
  meta_schema_version <- get_meta_schema_version(meta_schema)

  list(schema = schema, meta_schema_version = meta_schema_version)
}
