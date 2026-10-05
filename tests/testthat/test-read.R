test_that("can't read empty input", {
  ct <- jsonvalidate_js()
  expect_error(read_schema(NULL, ct),
               "zero length input")
  expect_error(read_schema(character(0), ct),
               "zero length input")
})


test_that("must read character input", {
  ct <- jsonvalidate_js()
  expect_error(read_schema(1, ct),
               "Expected a character vector")
})


test_that("sensible error on missing files", {
  ct <- jsonvalidate_js()
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
    read_schema(file.path(path, "b.json"), ct),
    "While reading 'b.json' > 'c.json'\nDid not find schema file 'c.json'",
    class = "jsonvalidate_read_error")
  expect_error(
    read_schema(file.path(path, "a.json"), ct),
    paste0("While reading 'a.json' > 'b.json' > 'c.json'\n",
           "Did not find schema file 'c.json'"),
    class = "jsonvalidate_read_error")
})


test_that("Read recursive schema", {
  ct <- jsonvalidate_js()
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
  dat <- read_schema(p, ct)
  expect_equal(length(dat$dependencies), 1)
  expect_equal(jsonlite::fromJSON(dat$dependencies)$id, "sexpression.json")

  v <- json_validator(p, engine = "ajv")
  expect_false(v("{}"))
  expect_true(v('["a"]'))
  expect_true(v('["a", ["b", "c", 3]]'))
})


test_that("can't read external schemas", {
  ct <- jsonvalidate_js()
  a <- c(
    '{',
    '"$ref": "https://example.com/schema.json"',
    '}')
  expect_error(read_schema(a, ct),
               "Don't yet support protocol-based sub schemas")
})


test_that("Conflicting schema versions", {
  ct <- jsonvalidate_js()
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
    read_schema(file.path(path, "a.json"), ct),
    "Conflicting subschema versions used:\n  - draft-04: b.json")
  expect_error(
    with_dir(path, read_schema(a, ct)),
    "Conflicting subschema versions used:\n.+- draft-07: \\(input string\\)")
  writeLines(sub("-04", "-07", b), file.path(path, "b.json"))
  x <- read_schema(file.path(path, "a.json"), ct)
  expect_equal(x$meta_schema_version, "draft-07")
})


test_that("Sensible reporting on syntax error", {
  ct <- jsonvalidate_js()
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
    read_schema(file.path(path, "parent.json"), ct),
    "While reading 'parent.json' > 'child.json'",
    class = "jsonvalidate_read_error")
})


test_that("schema string vs filename detection", {
  expect_false(read_schema_is_filename("''"))
  expect_false(read_schema_is_filename('""'))
  expect_false(read_schema_is_filename('{}'))
  expect_true(read_schema_is_filename('/foo/bar.json'))
  expect_true(read_schema_is_filename('bar.json'))
  expect_true(read_schema_is_filename('bar'))

  expect_false(read_schema_is_filename(character()))
  expect_false(read_schema_is_filename(c("a", "b")))
  expect_false(read_schema_is_filename(I('/foo/bar.json')))
})


test_that("sensible error if reading missing schema", {
  expect_error(
    read_schema("/file/that/does/not/exist.json"),
    "Schema '/file/that/does/not/exist.json' looks like a filename but")
})

test_that("can reference subsets of other schema", {
  ct <- jsonvalidate_js()
  a <- c(
    '{',
    '"$ref": "b.json#/definitions/b"',
    '}')
  b <- c(
    '{',
    '    "definitions": {',
    '        "b": {',
    '            "type": "string"',
    '        }',
    '    }',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(a, file.path(path, "a.json"))
  writeLines(b, file.path(path, "b.json"))
  schema <- read_schema(file.path(path, "a.json"), ct)
  expect_equal(length(schema$dependencies), 1)
  expect_equal(jsonlite::fromJSON(schema$dependencies)$id, "b.json")
})


test_that("a property named $ref is not read as a reference", {
  ct <- jsonvalidate_js()
  schema <- '{
    "definitions": {"name": {"type": "string"}},
    "properties": {
      "$ref": {"type": "string"},
      "name": {"$ref": "#/definitions/name"}
    }
  }'
  expect_equal(find_schema_dependencies(schema, ct), "#/definitions/name")
  expect_equal(
    find_schema_dependencies('{"properties": {"$ref": {"type": "string"}}}', ct),
    list())
})


test_that("draft-04 schema shaped like the OpenAPI 3.0 metaschema", {
  ## The OpenAPI 3.0 metaschema's PathItem has a property named "$ref"
  ## beside ordinary references to its own definitions.
  schema <- '{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "type": "object",
    "required": ["paths"],
    "properties": {
      "paths": {
        "type": "object",
        "additionalProperties": {"$ref": "#/definitions/PathItem"}
      }
    },
    "definitions": {
      "PathItem": {
        "type": "object",
        "properties": {
          "$ref": {"type": "string"},
          "summary": {"type": "string"}
        },
        "additionalProperties": false
      }
    }
  }'
  for (engine in c("imjv", "ajv")) {
    v <- json_validator(schema, engine = engine)
    expect_true(v('{"paths": {"/a": {"$ref": "#/b", "summary": "s"}}}'))
    expect_false(v('{"paths": {"/a": {"$ref": 1}}}'))
    expect_false(v('{"paths": {"/a": {"other": "s"}}}'))
  }
})


test_that("2020-12 schema shaped like the OpenAPI 3.1 metaschema", {
  ## The OpenAPI 3.1 metaschema's Reference object declares "$ref" in
  ## `properties` and is itself referenced through `$defs`.
  schema <- '{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "properties": {
      "parameter": {"$ref": "#/$defs/reference"}
    },
    "$defs": {
      "reference": {
        "type": "object",
        "properties": {
          "$ref": {"type": "string", "format": "uri-reference"},
          "summary": {"type": "string"}
        },
        "required": ["$ref"]
      }
    }
  }'
  v <- json_validator(schema, engine = "ajv")
  expect_true(v('{"parameter": {"$ref": "#/components/parameters/a"}}'))
  expect_false(v('{"parameter": {"$ref": 1}}'))
  expect_false(v('{"parameter": {"summary": "no reference"}}'))
})
