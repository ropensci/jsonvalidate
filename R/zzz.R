jsonvalidate_js <- function() {
  ct <- V8::v8()
  ct$source(system.file("bundle.js", package = "jsonvalidate"))
  ct
}
