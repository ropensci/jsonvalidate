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
               "data.hello: is required")
  expect_null(v("{hello: 'world'}", error = TRUE))
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
  expect_null(v("{hello: 'world'}", error = TRUE))
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
