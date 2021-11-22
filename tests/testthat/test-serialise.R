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

  v <- json_validator(schema, "ajv")
  x <- list(a = "x", b = "y")
  str <- json_serialise(x, v)
  expect_equal(str, '{"a":"x","b":["y"]}')
  expect_true(v(str))
})
