test_that("revdep returns reverse dependencies correctly", {
  installed <- matrix(
    c("pkgA", "pkgB", "pkgC", "pkgD",
      "",     "pkgA", "",     "pkgB",
      "",     "",     "pkgA", "",
      "",     "",     "",     "",
      "",     "",     "",     ""),
    nrow = 4,
    dimnames = list(NULL, c("Package", "Depends", "Imports", "Suggests", "LinkingTo"))
  )
  rownames(installed) <- installed[, "Package"]
  
  result <- cran_revdep("pkgA", recursive = TRUE, installed = installed)
  expect_equal(sort(result), sort(c("pkgB", "pkgC", "pkgD")))
})

test_that("cran_revdep respects ignore argument", {
  installed <- matrix(
    c("pkgA", "pkgB", "pkgC",
      "",     "pkgA", "pkgA",
      "",     "",     "",
      "",     "",     "",
      "",     "",     ""),
    nrow = 3,
    dimnames = list(NULL, c("Package", "Depends", "Imports", "Suggests", "LinkingTo"))
  )
  rownames(installed) <- installed[, "Package"]
  
  result <- cran_revdep("pkgA", ignore = "pkgC", installed = installed)
  expect_equal(result, "pkgB")
})

test_that("cran_revdep returns NULL and prints message if pkg is missing", {
  expect_message(result <- cran_revdep(), "Package name is required")
  expect_null(result)
})
