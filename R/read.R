read_schema <- function(x, v8) {
  if (length(x) == 0L) {
    stop("zero length input")
  }
  if (!is.character(x)) {
    stop("Expected a character vector")
  }

  children <- new.env(parent = emptyenv())
  parent <- NULL

  if (read_schema_is_filename(x)) {
    if (!file.exists(x)) {
      stop(sprintf("Schema '%s' looks like a filename but does not exist", x))
    }
    workdir <- dirname(x)
    filename <- basename(x)
    ret <- with_dir(workdir,
                    read_schema_filename(filename, children, parent, v8))
  } else {
    ret <- read_schema_string(x, children, parent, v8)
  }

  dependencies <- as.list(children)

  ret$meta_schema_version <- check_schema_versions(ret, dependencies)

  if (length(dependencies) > 0L) {
    ## It's quite hard to safely ship out the contents of the schema to
    ## ajv because it is assuming that we get ready-to-go js.  So we
    ## need to manually construct safe js here.  The alternatives all
    ## seem a bit ickier - we could pass in the string representation
    ## here and then parse it back out to json (JSON.parse) on each
    ## element which would be easier to control but it seems
    ## unnecessary.
    dependencies <- vcapply(dependencies, function(x)
      sprintf('{"id": "%s", "value": %s}', x$filename, x$schema))
    ret$dependencies <- sprintf("[%s]", paste(dependencies, collapse = ", "))
  }

  ret
}


read_schema_filename <- function(filename, children, parent, v8) {
  if (!file.exists(filename)) {
    stop(sprintf("Did not find schema file '%s'", filename))
  }

  schema <- paste(readLines(filename), collapse = "\n")

  meta_schema_version <- read_meta_schema_version(schema, v8)
  read_schema_dependencies(schema, children, c(filename, parent), v8)
  list(schema = schema, filename = filename,
       meta_schema_version = meta_schema_version)
}


read_schema_string <- function(string, children, parent, v8) {
  meta_schema_version <- read_meta_schema_version(string, v8)
  read_schema_dependencies(string, children, c("(string)", parent), v8)
  list(schema = string, filename = NULL,
       meta_schema_version = meta_schema_version)
}


read_schema_dependencies <- function(schema, children, parent, v8) {
  extra <- setdiff(find_schema_dependencies(schema, v8),
                   names(children))

  ## Remove relative references
  extra <- grep("^#", extra, invert = TRUE, value = TRUE)

  if (length(extra) == 0L) {
    return(NULL)
  }

  if (any(grepl("://", extra))) {
    stop("Don't yet support protocol-based sub schemas")
  }

  if (any(grepl("#/", extra))) {
    split <- strsplit(extra, "#/")
    extra <- lapply(split, "[[", 1)
  }

  for (p in extra) {
    ## Mark name as one that we will not descend further with
    children[[p]] <- NULL
    ## I feel this should be easier to do with withCallingHandlers,
    ## but not getting anywhere there.
    children[[p]] <- tryCatch(
      read_schema_filename(p, children, parent, v8),
      error = function(e) {
        if (!inherits(e, "jsonvalidate_read_error")) {
          chain <- paste(squote(c(rev(parent), p)), collapse = " > ")
          e$message <- sprintf("While reading %s\n%s", chain, e$message)
          class(e) <- c("jsonvalidate_read_error", class(e))
          e$call <- NULL
        }
        stop(e)
      })
  }
}


read_meta_schema_version <- function(schema, v8) {
  meta_schema <- v8$call("get_meta_schema_version", V8::JS(schema))
  if (is.null(meta_schema)) {
    return(NULL)
  }

  regex <- paste0("^https*://json-schema.org/",
                  "(draft-\\d{2}|draft/\\d{4}-\\d{2})/schema#*$")
  version <- gsub(regex, "\\1", meta_schema)

  version
}


find_schema_dependencies <- function(schema, v8) {
  v8$call("find_reference", V8::JS(schema))
}


check_schema_versions <- function(schema, dependencies) {
  version <- schema$meta_schema_version

  versions <- lapply(dependencies, "[[", "meta_schema_version")
  versions <- versions[!vlapply(versions, is.null)]
  versions <- vcapply(versions, identity)
  version_dependencies <- unique(versions)

  if (length(versions) == 0L) {
    return(version)
  }

  versions_used <- c(set_names(version, schema$filename %||% "(input string)"),
                     versions)
  versions_used_unique <- unique(versions_used)
  if (length(versions_used_unique) == 1L) {
    return(versions_used_unique)
  }

  err <- split(names(versions_used), versions_used)
  err <- vcapply(names(err), function(v)
    sprintf("  - %s: %s", v, paste(err[[v]], collapse = ", ")),
    USE.NAMES = FALSE)
  stop(paste0("Conflicting subschema versions used:\n",
              paste(err, collapse = "\n")),
       call. = FALSE)
}


read_schema_is_filename <- function(x) {
  RE_JSON <- "[{['\"]"
  !(length(x) != 1 || inherits(x, "AsIs") || grepl(RE_JSON, x))
}
