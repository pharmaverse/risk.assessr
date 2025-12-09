test_that("extracts package names correctly from typical dependency strings", {
  expect_equal(
    extract_dependency_package_names("ggplot2 (>= 3.3.0), dplyr, tidyr"),
    c("ggplot2", "dplyr", "tidyr")
  )
})

test_that("removes 'R' from the list", {
  expect_equal(
    extract_dependency_package_names("R (>= 3.5.0), stringr"),
    "stringr"
  )
})

test_that("returns empty character vector for NA input", {
  expect_equal(
    extract_dependency_package_names(NA),
    character()
  )
})

test_that("handles whitespace and version constraints", {
  expect_equal(
    extract_dependency_package_names("  purrr (>= 0.3.0) , tibble "),
    c("purrr", "tibble")
  )
})

test_that("returns empty vector for empty string", {
  expect_equal(
    extract_dependency_package_names(""),
    character()
  )
})

test_that("ignores malformed entries gracefully", {
  test <- 
  expect_equal(
    extract_dependency_package_names(" , , , "),
    character()
  )
})
