context("validator")

test_that("simple case works", {
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
  expect_error(v("{}", error=TRUE),
               "data.hello: is required")
  expect_null(v("{hello: 'world'}", error=TRUE))
})
