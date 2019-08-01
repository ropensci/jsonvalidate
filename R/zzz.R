env <- new.env(parent = emptyenv())


prepare_js <- function() {
  ct <- V8::v8()
  ct$source(system.file("bundle.js", package = "jsonvalidate"))
  ct
}


## This can't be reliably tested - it's called during package startup
## and outside of covr's measurements.
.onLoad <- function(libname, pkgname) {
  env$ct <- prepare_js() # nocov
}
