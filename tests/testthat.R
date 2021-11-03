if (identical(Sys.getenv("NOT_CRAN"), "true")) {
library(testthat)
library(jsonvalidate)

test_check("jsonvalidate")
}
