test_that("clean_up_dependencies extracts and cleans multiple dependency strings", {
  input <- c("pkgA (>= 1.0), pkgB", "R (>= 3.5.0), pkgC")
  expected <- c("pkgA", "pkgB", "pkgC")
  
  result <- clean_up_dependencies(input)
  
  expect_equal(sort(result), sort(expected))
})

test_that("clean_up_dependencies handles empty input", {
  expect_equal(clean_up_dependencies(character()), character())
})

test_that("clean_up_dependencies removes duplicates", {
  input <- c("pkgA, pkgB", "pkgB, pkgC")
  expected <- c("pkgA", "pkgB", "pkgC")
  
  result <- clean_up_dependencies(input)
  
  expect_equal(sort(result), sort(expected))
})

test_that("clean_up_dependencies handles NA values", {
  input <- c(NA, "pkgX (>= 1.0)")
  expected <- "pkgX"
  
  result <- clean_up_dependencies(input)
  
  expect_equal(result, expected)
})
