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
  expect_equal(str, structure('{"a":"x","b":["y"]}', class = "json"))
  expect_true(v(str))
  expect_equal(json_serialise(x, schema), str)
})


test_that("Can't use imjv with serialise", {
  v <- json_validator("{}", "imjv")
  x <- list(a = "x", b = "y")
  expect_error(
    json_serialise(x, v),
    "json_serialise is only supported with engine 'ajv'")
})


test_that("Require validator to use serialise", {
  x <- list(a = "x", b = "y")
  expect_error(
    json_serialise(x, NULL),
    "Invalid input for 'schema'")
})
