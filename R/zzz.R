jsonvalidate_js <- function() {
  ct <- V8::v8()
  ct$source(system.file("bundle.js", package = "jsonvalidate"))
  ct
}


## Via Gabor, remove NOTE about Imports while not loading R6 at load.
ignore_unused_imports <- function() {
  R6::R6Class
}
