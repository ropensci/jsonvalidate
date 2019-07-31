env <- new.env(parent = emptyenv())


prepare_js <- function() {
  ct <- V8::v8()
  ct$source(system.file("bundle.js", package = "jsonvalidate"))
  ct
}


.onLoad <- function(libname, pkgname) {
  env$ct <- prepare_js()
}
