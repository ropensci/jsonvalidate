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
    "While reading 'b.json' > 'c.json'\nDid not find schema file 'c.json'",
    class = "jsonvalidate_read_error")
  expect_error(
    read_schema(file.path(path, "a.json"), env$ct),
    paste0("While reading 'a.json' > 'b.json' > 'c.json'\n",
           "Did not find schema file 'c.json'"),
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


test_that("can't read external schemas", {
  a <- c(
    '{',
    '"$ref": "https://example.com/schema.json"',
    '}')
  expect_error(read_schema(a, env$ct),
               "Don't yet support protocol-based sub schemas")
})


test_that("invalid schema version", {
  schema <- "{
    '$schema': 'http://json-schema.org/draft-99/schema#',
    'type': 'object',
    'properties': {
      'a': {
        'const': 'foo'
      }
    }
  }"
  expect_error(
    read_schema(schema, env$ct),
    "Unknown meta schema version 'draft-99'")
})


test_that("Conflicting schema versions", {
  a <- c(
    '{',
    '  "$schema": "http://json-schema.org/draft-07/schema#",',
    '  "$ref": "b.json"',
    '}')
  b <- c(
    '{',
    '  "$schema": "http://json-schema.org/draft-04/schema#",',
    '  "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(a, file.path(path, "a.json"))
  writeLines(b, file.path(path, "b.json"))
  expect_error(
    read_schema(file.path(path, "a.json"), env$ct),
    "Conflicting subschema versions used:\n  - draft-04: b.json")
  expect_error(
    with_dir(path, read_schema(a, env$ct)),
    "Conflicting subschema versions used:\n.+- draft-07: \\(input string\\)")
  writeLines(sub("-04", "-07", b), file.path(path, "b.json"))
  x <- read_schema(file.path(path, "a.json"), env$ct)
  expect_equal(x$meta_schema_version, "draft-07")
})


test_that("Sensible reporting on syntax error", {
  parent <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "hello": {',
    '            "$ref": "child.json"',
    '        }',
    '    },',
    '    "required": ["hello"],',
    '    "additionalProperties": false',
    '}')
  child <- c(
    '{',
    '    "id": "child"',
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(child, file.path(path, "child.json"))
  expect_error(
    read_schema(file.path(path, "parent.json"), env$ct),
    "While reading 'parent.json' > 'child.json'",
    class = "jsonvalidate_read_error")
})
