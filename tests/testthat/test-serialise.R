test_that("Can safely serialise a json object using a schema", {
  schema <- '{
    "type": "object",
    "properties": {
        "a": {
            "type": "string"
        },
        "b": {
            "type": "array",
            "items": {
                "type": "string"
            }
        }
    }
}'

  v <- json_schema$new(schema, "ajv")
  x <- list(a = "x", b = "y")
  str <- v$serialise(x)
  expect_equal(str, structure('{"a":"x","b":["y"]}', class = "json"))
  expect_true(v$validate(str))
  expect_equal(json_serialise(x, schema), str)
})


test_that("Can't use imjv with serialise", {
  v <- json_schema$new("{}", "imjv")
  x <- list(a = "x", b = "y")
  expect_error(
    v$serialise(x),
    "json_serialise is only supported with engine 'ajv'")
})
