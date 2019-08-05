context("read")

test_that("can't read empty input", {
  expect_error(read_schema(NULL, env$ct),
               "zero length input")
  expect_error(read_schema(character(0), env$ct),
               "zero length input")
})


test_that("must read character input", {
  expect_error(read_schema(1, env$ct),
               "Expected a character vector")
})


test_that("sensible error on missing files", {
  a <- c(
    '{',
    '"$ref": "b.json"',
    '}')
  b <- c(
    '{',
    '"$ref": "c.json"',
    '}')
  c <- c(
    '{',
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(a, file.path(path, "a.json"))
  writeLines(b, file.path(path, "b.json"))
  expect_error(
    read_schema(file.path(path, "b.json"), env$ct),
    "While reading 'b.json'\nDid not find schema file 'c.json'",
    class = "jsonvalidate_read_error")
  expect_error(
    read_schema(file.path(path, "a.json"), env$ct),
    "While reading 'a.json' > 'b.json'\nDid not find schema file 'c.json'",
    class = "jsonvalidate_read_error")
})


test_that("Read recursive schema", {
  sexpression <- c(
    '{',
    '  "oneOf": [',
    '  {"type": "string"},',
    '  {"type": "number"},',
    '  {"type": "array", "items": {"$ref": "sexpression.json"}}',
    ']}')

  path <- tempfile()
  dir.create(path)
  p <- file.path(path, "sexpression.json")
  writeLines(sexpression, p)
  dat <- read_schema(p, env$ct)
  expect_equal(length(dat$dependencies), 1)
  expect_equal(jsonlite::fromJSON(dat$dependencies)$id, "sexpression.json")

  v <- json_validator(p, engine = "ajv")
  expect_false(v("{}"))
  expect_true(v('["a"]'))
  expect_true(v('["a", ["b", "c", 3]]'))
})
