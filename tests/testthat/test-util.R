test_that("get_string error cases", {
  expect_error(get_string(character(0), "thing"),
               "zero length input for thing")
  expect_error(get_string(1, "thing"),
               "Expected a character vector for thing")
})


test_that("get_string reads files as a string", {
  path <- tempfile()
  writeLines(c("some", "test"), path)
  expect_equal(get_string(path), "some\ntest")
})


test_that("detect probable files", {
  path <- tempfile()
  expect_false(refers_to_file('{"a": 1}'))
  expect_false(refers_to_file(structure("1", class = "json")))
  expect_false(refers_to_file(c("a", "b")))
  expect_false(refers_to_file(path))
  writeLines(c("some", "test"), path)
  expect_true(refers_to_file(path))
})


test_that("get_string concatenates character vectors", {
  expect_equal(get_string(c("some", "text")),
               "some\ntext")
})


test_that("get_string passes along strings", {
  expect_equal(get_string("some\ntext"),
               "some\ntext")
  ## Probably not ideal:
  expect_equal(get_string("file_that_does_not_exist.json"),
               "file_that_does_not_exist.json")
})


test_that("control printing imjv notice", {
  testthat::skip_if_not_installed("withr")
  withr::with_options(
    list(jsonvalidate.no_note_imjv = NULL),
    expect_message(note_imjv("note", TRUE), "note"))
  withr::with_options(
    list(jsonvalidate.no_note_imjv = FALSE),
    expect_message(note_imjv("note", TRUE), "note"))
  withr::with_options(
    list(jsonvalidate.no_note_imjv = TRUE),
    expect_silent(note_imjv("note", TRUE)))
  withr::with_options(
    list(jsonvalidate.no_note_imjv = NULL),
    expect_silent(note_imjv("note", FALSE)))
  withr::with_options(
    list(jsonvalidate.no_note_imjv = FALSE),
    expect_message(note_imjv("note", FALSE), "note"))
  withr::with_options(
    list(jsonvalidate.no_note_imjv = TRUE),
    expect_silent(note_imjv("note", TRUE)))
})

test_that("can check if path includes dir", {
  expect_false(path_includes_dir(NULL))
  expect_false(path_includes_dir("file.json"))
  expect_true(path_includes_dir("the/file.json"))
})

test_that("can read file with no trailing newline", {
  path <- tempfile()
  writeLines("12345678", path, sep="")

  # Check that we wrote just what we wanted and no more.
  expect_equal(file.info(path)$size, 8)

  result <- expect_silent(get_string(path))
  expect_equal(result, "12345678")
})
