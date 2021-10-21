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
