## NOTE: so far as I can see this is not valid json, nor is it
## sensible json schema (the 'required' kw should be an array)
test_that("is-my-json-valid", {
  str <- "{
  required: true,
  type: 'object',
  properties: {
    hello: {
      required: true,
      type: 'string'
    }
  }
}"

  v <- json_validator(str, engine = "imjv")
  expect_false(v("{}"))
  expect_true(v("{hello: 'world'}"))

  expect_false(json_validate("{}", str, engine = "imjv"))
  expect_true(json_validate("{hello: 'world'}", str, engine = "imjv"))

  f <- tempfile()
  writeLines(str, f)
  v <- json_validator(f, engine = "imjv")
  expect_false(v("{}"))
  expect_true(v("{hello: 'world'}"))

  v <- json_validator("schema.json", engine = "imjv")
  expect_error(v("{}", error = TRUE),
               "data.hello: is required",
               class = "validation_error")
  expect_true(v("{hello: 'world'}", error = TRUE))
})


test_that("simple case works", {
  schema <- str <- '{
  "type": "object",
  required: ["hello"],
  "properties": {
    "hello": {
      "type": "string"
    }
  }
}'
  v <- json_validator(str, "ajv")
  expect_false(v("{}"))
  expect_true(v("{hello: 'world'}"))

  expect_false(json_validate("{}", str))
  expect_true(json_validate("{hello: 'world'}", str))

  f <- tempfile()
  writeLines(str, f)
  v <- json_validator(f)
  expect_false(v("{}"))
  expect_true(v("{hello: 'world'}"))

  v <- json_validator("schema2.json", "ajv")
  expect_error(v("{}", error = TRUE), "hello", class = "validation_error")
  expect_true(v("{hello: 'world'}", error = TRUE))
})


test_that("verbose output", {
  schema <- str <- '{
  "type": "object",
  required: ["hello"],
  "properties": {
    "hello": {
      "type": "string"
    }
  }
}'
  v <- json_validator(str, "ajv")
  res <- v("{}", verbose = TRUE)
  expect_false(res)
  expect_s3_class(attr(res, "errors"), "data.frame")
})


test_that("const keyword is supported in draft-06, not draft-04", {
  schema <- "{
    '$schema': 'http://json-schema.org/draft-04/schema#',
    'type': 'object',
    'properties': {
      'a': {
        'const': 'foo'
      }
    }
  }"

  expect_true(json_validate("{'a': 'foo'}", schema, engine = "ajv"))
  expect_true(json_validate("{'a': 'bar'}", schema, engine = "ajv"))

  ## Switch to draft-06
  schema <- gsub("draft-04", "draft-06", schema)

  expect_true(json_validate("{'a': 'foo'}", schema, engine = "ajv"))
  expect_false(json_validate("{'a': 'bar'}", schema, engine = "ajv"))
})

test_that("if/then/else keywords are supported in draft-07, not draft-04", {
  schema <- "{
    '$schema': 'http://json-schema.org/draft-04/schema#',
    'type': 'object',
    'if': {
      'properties': {
        'a': {'type': 'number', 'minimum': 1}
      }
    },
    'then': {
      'required': ['b']
    },
    'else': {
      'required': ['c']
    }
  }"

  expect_true(json_validate("{'a': 5, 'b': 5}", schema, engine = "ajv"))
  expect_true(json_validate("{'a': 0, 'b': 5}", schema, engine = "ajv"))

  ## Switch to draft-07
  schema <- gsub("draft-04", "draft-07", schema)

  expect_true(json_validate("{'a': 5, 'b': 5}", schema, engine = "ajv"))
  expect_false(json_validate("{'a': 5, 'c': 5}", schema, engine = "ajv"))
})


test_that("subschema validation works", {
  schema <- '{
    "$schema": "http://json-schema.org/draft-06/schema#",
    "definitions":  {
      "Goodbye": {
        type: "object",
        properties: {"goodbye": {type: "string"}},
        "required": ["goodbye"]
      },
      "Hello": {
        type: "object",
        properties: {"hello": {type: "string"}},
        "required": ["hello"]
      },
      "Conversation": {
        "anyOf": [
          {"$ref": "#/definitions/Hello"},
          {"$ref": "#/definitions/Goodbye"},
        ]
      }
      },
    "$ref": "#/definitions/Conversation"
  }'

  val_goodbye <- json_validator(schema, "ajv", "#/definitions/Goodbye")

  expect_true(val_goodbye("{'goodbye': 'failure'}"))
  expect_false(val_goodbye("{'hello': 'failure'}"))

  val_hello <- json_validator(schema, "ajv", "#/definitions/Hello")

  expect_false(val_hello("{'goodbye': 'failure'}"))
  expect_true(val_hello("{'hello': 'failure'}"))
})


test_that("can't use subschema reference with imjv", {
  expect_error(json_validator("{}", engine = "imjv",
                              reference = "definitions/sub"),
               "subschema validation only supported with engine 'ajv'")
})

test_that("can't use nested schemas with imjv", {
  testthat::skip_if_not_installed("withr")
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
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(child, file.path(path, "child.json"))

  withr::with_options(
    list(jsonvalidate.no_note_imjv = FALSE),
    expect_message(
      v <- json_validator(file.path(path, "parent.json"), engine = "imjv"),
      "Schema references are only supported with engine 'ajv'"))
  ## We incorrectly don't find this invalid, because we never read the
  ## child schema; the user should have used ajv!
  expect_true(v('{"hello": 1}'))
})


test_that("can't use invalid engines", {
  expect_error(json_validator("{}", engine = "magic"),
               "Unknown engine 'magic'")
})


test_that("can't use new schema versions with imjv", {
  testthat::skip_if_not_installed("withr")
  schema <- "{
    '$schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'properties': {
      'a': {
        'const': 'foo'
      }
    }
  }"
  withr::with_options(
    list(jsonvalidate.no_note_imjv = FALSE),
    expect_message(
      v <- json_schema$new(schema, "imjv"),
      "meta schema version other than 'draft-04' is only supported with"))
  ## We incorrectly don't find this invalid, because imjv does not
  ## understand the const keyword.
  expect_true(v$validate('{"a": "bar"}'))
})


test_that("Simple file references work", {
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
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(child, file.path(path, "child.json"))

  v <- json_validator(file.path(path, "parent.json"), engine = "ajv")
  expect_false(v("{}"))
  expect_true(v('{"hello": "world"}'))
})


test_that("Referenced schemas have their ids replaced", {
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
    '    "id": "child",',
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(child, file.path(path, "child.json"))

  expect_silent(
    v <- json_validator(file.path(path, "parent.json"), engine = "ajv"))
  expect_false(v("{}"))
  expect_true(v('{"hello": "world"}'))
})


test_that("file references in subdirectories work", {
  parent <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "hello": {',
    '            "$ref": "sub/child.json"',
    '        }',
    '    },',
    '    "required": ["hello"],',
    '    "additionalProperties": false',
    '}')
  child <- c(
    '{',
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  subdir <- file.path(path, "sub")
  dir.create(subdir)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(child, file.path(subdir, "child.json"))

  v <- json_validator(file.path(path, "parent.json"), engine = "ajv")
  expect_false(v("{}"))
  expect_true(v('{"hello": "world"}'))
})


test_that("chained file references work", {
  parent <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "hello": {',
    '            "$ref": "sub/middle.json"',
    '        }',
    '    },',
    '    "required": ["hello"],',
    '    "additionalProperties": false',
    '}')
  middle <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "greeting": {',
    '            "$ref": "child.json"',
    '        }',
    '    },',
    '    "required": ["greeting"],',
    '    "additionalProperties": false',
    '}')
  child <- c(
    '{',
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  subdir <- file.path(path, "sub")
  dir.create(subdir)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(middle, file.path(subdir, "middle.json"))
  writeLines(child, file.path(subdir, "child.json"))

  v <- json_validator(file.path(path, "parent.json"), engine = "ajv")
  expect_false(v("{}"))
  expect_true(v('{"hello": { "greeting": "world"}}'))
  expect_false(v('{"hello": { "greeting": 2}}'))
})


test_that("absolute file references throw error", {
  parent <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "greeting": {',
    '            "$ref": "%s"',
    '        },',
    '        "address": {',
    '            "$ref": "%s"',
    '        }',
    '    },',
    '    "required": ["greeting", "address"],',
    '    "additionalProperties": false',
    '}')
  child <- c(
    '{',
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  child_path1 <- file.path(path, "child1.json")
  writeLines(child, child_path1)
  child_path2 <- file.path(path, "child2.json")
  writeLines(child, child_path2)
  parent_path <- file.path(path, "parent.json")
  writeLines(sprintf(paste0(parent, collapse = "\n"),
                     normalizePath(child_path1), normalizePath(child_path2)),
    parent_path)

  expect_error(json_validator(parent_path, engine = "ajv"),
               "'\\$ref' paths must be relative, got absolute path\\(s\\)")
})


test_that("chained file references return useful error", {
  parent <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "hello": {',
    '            "$ref": "sub/middle.json"',
    '        }',
    '    },',
    '    "required": ["hello"],',
    '    "additionalProperties": false',
    '}')
  middle <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "greeting": {',
    '            "$ref": "sub/child.json"',
    '        }',
    '    },',
    '    "required": ["greeting"],',
    '    "additionalProperties": false',
    '}')
  child <- c(
    '{',
    '    "type": "string"',
    '}')
  path <- tempfile()
  dir.create(path)
  subdir <- file.path(path, "sub")
  dir.create(subdir)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(middle, file.path(subdir, "middle.json"))
  writeLines(child, file.path(subdir, "child.json"))

  expect_error(
    json_validator(file.path(path, "parent.json"), engine = "ajv"),
    "Did not find schema file 'sub/child.json' relative to 'sub/middle.json'")
})


test_that("Can validate fraction of a json object", {
  schema <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "x": {',
    '            type: "string"',
    '        },',
    '    },',
    '    "required": ["x"]',
    '}')
  data <- c(
    '{',
    '    "a": {',
    '        "x": "string"',
    '    },',
    '    "b": {',
    '        y: 1',
    '    }',
    '}')

  expect_false(json_validate(data, schema, engine = "ajv"))
  expect_true(json_validate(data, schema, engine = "ajv", query = "a"))
  expect_false(json_validate(data, schema, engine = "ajv", query = "b"))

  expect_error(
    json_validate(data, schema, engine = "imjv", query = "c"),
    "Queries are only supported with engine 'ajv'")

  expect_error(
    json_validate(data, schema, engine = "ajv", query = "c"),
    "Query did not match any element in the data")

  expect_error(
    json_validate("[]", schema, engine = "ajv", query = "c"),
    "Query only supported with object json")
  expect_error(
    json_validate("null", schema, engine = "ajv", query = "c"),
    "Query only supported with object json")
})


test_that("complex jsonpath queries are rejected", {
  msg <- "Full json-path support is not implemented"
  expect_error(query_validate("foo/bar"), msg)
  expect_error(query_validate("foo?"), msg)
  expect_error(query_validate("$foo"), msg)
  expect_error(query_validate("foo(bar)"), msg)
  expect_error(query_validate("foo[0]"), msg)
  expect_error(query_validate("foo@bar"), msg)
})


test_that("simple jsonpath is passed along", {
  expect_identical(query_validate("foo"), "foo")
  expect_identical(query_validate(NULL), V8::JS("null"))
})


test_that("stray null values in a schema are ok", {
  ## This is stripped down version of the vegalite schema 3.3.0 which
  ## includes a block
  ##
  ##   "invalidValues": {
  ##     "description": "Defines how Vega-Lite should handle ...",
  ##     "enum": [
  ##       "filter",
  ##       null
  ##     ],
  ##     "type": [
  ##       "string",
  ##       "null"
  ##     ]
  ##   },
  ##
  ## which used to break the reference detection by throwing an error
  ## when the schema was read.
  schema <- '{
    "type": "object",
    "properties": {
      "a": {
        "enum": ["value", null]
      }
    }
  }'
  ct <- jsonvalidate_js()
  expect_error(read_schema(schema, ct), NA)
})


test_that("Referencing definition in another file works", {
  parent <- c(
    '{',
    '    "type": "object",',
    '    "properties": {',
    '        "hello": {',
    '            "$ref": "child.json#/definitions/greeting"',
    '        }',
    '    },',
    '    "required": ["hello"],',
    '    "additionalProperties": false',
    '}')
  child <- c(
    '{',
    '    "definitions": {',
    '        "greeting": {',
    '            "type": "string"',
    '        }',
    '    }',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(child, file.path(path, "child.json"))

  v <- json_validator(file.path(path, "parent.json"), engine = "ajv")
  expect_false(v("{}"))
  expect_true(v('{"hello": "world"}'))
  invalid <- v('{"hello": ["thing"]}', verbose = TRUE)
  expect_false(invalid)
  error <- attr(invalid, "errors", TRUE)
  expect_equal(error$schemaPath, "child.json#/definitions/greeting/type")
  expect_equal(error$message, "must be string")
})


test_that("schema can contain IDs", {
  schema <- c(
    '{',
    '    "$id": "http://example.com/schemas/thing.json",',
    '    "type": "object",',
    '    "properties": {',
    '        "hello": {',
    '            "type": "string"',
    '        }',
    '    },',
    '    "required": ["hello"],',
    '    "additionalProperties": false',
    '}')

  path <- tempfile()
  dir.create(path)
  writeLines(schema, file.path(path, "schema.json"))

  v <- json_validator(file.path(path, "schema.json"), engine = "ajv")
  expect_false(v("{}"))
  expect_true(v("{hello: 'world'}"))
})


test_that("Parent schema with URL ID works", {
  parent <- c(
    '{',
    '    "$id": "http://example.com/schemas/thing.json",',
    '    "type": "object",',
    '    "properties": {',
    '        "hello": {',
    '            "$ref": "child.json#/definitions/greeting"',
    '        }',
    '    },',
    '    "required": ["hello"],',
    '    "additionalProperties": false',
    '}')
  child <- c(
    '{',
    '    "definitions": {',
    '        "first": {',
    '            "type": "string"',
    '        },',
    '        "greeting": {',
    '            "type": "object",',
    '            "properties": {',
    '                "name": {',
    '                    "type": "string"',
    '                },',
    '                "another_prop": {',
    '                    "type": "number"',
    '                }',
    '             }',
    '        }',
    '    }',
    '}')
  path <- tempfile()
  dir.create(path)
  writeLines(parent, file.path(path, "parent.json"))
  writeLines(child, file.path(path, "child.json"))

  v <- json_validator(file.path(path, "parent.json"), engine = "ajv")
  expect_false(v("{}"))
  expect_true(v('{"hello": {"name": "a name", "another_prop": 2}}'))
})

test_that("format keyword works", {
  str <- '{
  "type": "object",
  "required": ["date"],
  "properties": {
    "date": {
      "type": "string",
      "format": "date-time"
    }
  }
}'
  v <- json_validator(str, "ajv")
  expect_false(v("{'date': '123'}"))
  expect_true(v("{'date': '2018-11-13T20:20:39+00:00'}"))
})

test_that("format keyword works in draft-04", {
  str <- '{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "required": ["date"],
  "properties": {
    "date": {
      "type": "string",
      "format": "date-time"
    }
  }
}'
  v <- json_validator(str, "ajv", strict = TRUE)
  expect_false(v("{'date': '123'}"))
  expect_true(v("{'date': '2018-11-13T20:20:39+00:00'}"))
})

test_that("unknown format type throws an error if in strict mode", {
  str <- '{
  "type": "object",
  "required": ["date"],
  "properties": {
    "date": {
      "type": "string",
      "format": "test"
    }
  }
}'
  expect_error(json_validator(str, "ajv", strict = TRUE),
               paste0('Error: unknown format "test" ignored in schema at ',
                      'path "#/properties/date"'))

  ## Warnings printed in non-strict mode; these include some annoying
  ## newlines from the V8 engine, so using capture.output to stop
  ## these messing up testthat output
  capture.output(
    msg <- capture_warnings(v <- json_validator(str, "ajv", strict = FALSE)))
  expect_equal(msg[1], paste0('unknown format "test" ignored in ',
                              'schema at path "#/properties/date"'))
  expect_true(v("{'date': '123'}"))
})

test_that("json_validate can be run in strict mode", {
  schema <- "{
    '$schema': 'http://json-schema.org/draft-04/schema#',
    'type': 'object',
    'properties': {
      'a': {
        'const': 'foo'
      }
    },
    'reference': '1234'
  }"

  expect_true(json_validate("{'a': 'foo'}", schema, engine = "ajv"))

  expect_error(
    json_validate("{'a': 'foo'}", schema, engine = "ajv", strict = TRUE),
    'Error: strict mode: unknown keyword: "reference"')
})


test_that("validation works with 2019-09 schema version", {
  schema <- "{
    '$schema': 'http://json-schema.org/draft-07/schema#',
    '$defs': {
      'toggle': {
        '$id': '#toggle',
        'type': [ 'boolean', 'null' ],
        'default': null
      }
    },
    'type': 'object',
    'properties': {
      'enabled': {
        '$ref': '#toggle',
        'default': true
      }
    }
  }"

  expect_true(json_validate("{'enabled': true}", schema, engine = "ajv"))
  expect_false(json_validate("{'enabled': 'test'}", schema, engine = "ajv"))

  ## Switch to draft/2019-09
  schema <- gsub("http://json-schema.org/draft-07/schema#",
                 "https://json-schema.org/draft/2019-09/schema#", schema)
  ## draft/2019-09 doesn't allow #plain-name form of $id
  expect_error(json_validator(schema, engine = "ajv"),
               "Error: schema is invalid:")

  schema <- "{
    '$schema': 'https://json-schema.org/draft/2019-09/schema#',
    '$defs': {
      'toggle': {
        '$anchor': 'toggle',
        'type': [ 'boolean', 'null' ],
        'default': null
      }
    },
    'type': 'object',
    'properties': {
      'enabled': {
        '$ref': '#toggle',
        'default': true
      }
    }
  }"
  expect_true(json_validate("{'enabled': true}", schema, engine = "ajv"))
  expect_false(json_validate("{'enabled': 'test'}", schema, engine = "ajv"))
})

test_that("validation works with 2020-12 schema version", {
  schema <- "{
    '$schema': 'https://json-schema.org/draft/2020-12/schema#',
    '$defs': {
      'toggle': {
        '$anchor': 'toggle',
        'type': [ 'boolean', 'null' ],
        'default': null
      }
    },
    'type': 'object',
    'properties': {
      'enabled': {
        '$ref': '#toggle',
        'default': true
      }
    }
  }"

  expect_true(json_validate("{'enabled': true}", schema, engine = "ajv"))
  expect_false(json_validate("{'enabled': 'test'}", schema, engine = "ajv"))
})


test_that("ajv requires a valid meta schema version", {
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
    json_validator(schema, engine = "ajv"),
    "Unknown meta schema version 'draft-99'")
})
