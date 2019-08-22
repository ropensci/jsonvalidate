context("validator")


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

  v <- json_validator(str)
  expect_false(v("{}"))
  expect_true(v("{hello: 'world'}"))

  expect_false(json_validate("{}", str))
  expect_true(json_validate("{hello: 'world'}", str))

  f <- tempfile()
  writeLines(str, f)
  v <- json_validator(f)
  expect_false(v("{}"))
  expect_true(v("{hello: 'world'}"))

  v <- json_validator("schema.json")
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
  expect_is(attr(res, "errors"), "data.frame")
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
        'a': {'minimum': 1}
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

  expect_error(
    json_validator(file.path(path, "parent.json"), engine = "imjv"),
    "Schema references are only supported with engine 'ajv'")
})


test_that("can't use invalid engines", {
  expect_error(json_validator("{}", engine = "magic"),
               "Unknown engine 'magic'")
})


test_that("can't use new schema versions with imjv", {
  schema <- "{
    '$schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'properties': {
      'a': {
        'const': 'foo'
      }
    }
  }"
  expect_error(
    json_validator(schema, engine = "imjv"),
    "meta schema version 'draft-07' is only supported with engine 'ajv'")
})


test_that("package support", {
  res <- prepare_js()
  expect_is(res, "V8")
  expect_setequal(names(res$get("validators")),
                  c("imjv", "ajv"))
  s <- res$call("validator_stats")
  expect_equal(s$imjv, 0)
  expect_equal(s$ajv, 0)
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
