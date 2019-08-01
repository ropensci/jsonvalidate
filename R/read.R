read_schema <- function(x, v8) {
  schema <- get_string(x, "schema")
  meta_schema_version <- read_meta_schema_version(schema, v8)

  list(schema = schema, meta_schema_version = meta_schema_version)
}


read_meta_schema_version <- function(schema, v8) {
  meta_schema <- v8$eval(sprintf("get_meta_schema_version(%s)", schema))

  regex <- "^http://json-schema.org/(draft-\\d{2})/schema#$"
  version <- gsub(regex, "\\1", meta_schema)

  versions_legal <- c("draft-04", "draft-06", "draft-07")
  if (!version %in% versions_legal) {
    return(NULL)
  }

  version
}
