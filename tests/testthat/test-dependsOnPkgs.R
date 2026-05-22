test_that("dependsOnPkgs returns direct reverse dependencies", {
  installed <- matrix(
    c("pkgA", "pkgB", "pkgC", "pkgD",  # Package
      "",     "pkgA", "",     "pkgB",  # Depends
      "",     "",     "pkgA", "",      # Imports
      "",     "",     "",     "pkgC",  # Suggests
      "",     "",     "",     ""),     # LinkingTo
    nrow = 4,
    dimnames = list(NULL, c("Package", "Depends", "Imports", "Suggests", "LinkingTo"))
  )
  rownames(installed) <- installed[, "Package"]
  
  result <- dependsOnPkgs("pkgA", dependencies = "strong", recursive = FALSE, installed = installed)
  expect_equal(sort(result), sort(c("pkgB", "pkgC")))
})


test_that("dependsOnPkgs returns recursive reverse dependencies", {
  installed <- matrix(
    c("pkgA", "pkgB", "pkgC", "pkgD",  # Package
      "pkgB", "",     "",     "pkgA",  # Depends
      "",     "pkgA", "",     "pkgB",  # Imports
      "",     "",     "",     "",      # Suggests
      "",     "",     "",     ""),     # LinkingTo
    nrow = 4,
    dimnames = list(NULL, c("Package", "Depends", "Imports", "Suggests", "LinkingTo"))
  )
  rownames(installed) <- installed[, "Package"]
  
  result <- dependsOnPkgs("pkgA", dependencies = "most", recursive = TRUE, installed = installed)
  expect_equal(sort(result), sort(c("pkgB", "pkgD")))
})

test_that("dependsOnPkgs handles no dependencies", {
  installed <- matrix(
    c("pkgX", "pkgY",  # Package
      "",     "",      # Depends
      "",     "",      # Imports
      "",     ""),     # LinkingTo
    nrow = 2,
    dimnames = list(NULL, c("Package", "Depends", "Imports", "LinkingTo"))
  )
  
  rownames(installed) <- installed[, "Package"]
  
  result <- dependsOnPkgs("pkgX", dependencies = "strong", recursive = TRUE, installed = installed)
  expect_equal(result, character(0))
})

test_that("dependsOnPkgs handles multiple input packages", {
  installed <- matrix(
    c("pkgA", "pkgB", "pkgC",  # Package
      "pkgB", "",     "pkgA",  # Depends
      "",     "pkgA", "",      # Imports
      "",     "",     ""),     # LinkingTo
    nrow = 3,
    dimnames = list(NULL, c("Package", "Depends", "Imports", "LinkingTo"))
  )
  
  rownames(installed) <- installed[, "Package"]
  
  result <- dependsOnPkgs(c("pkgA", "pkgB"), dependencies = "strong", recursive = TRUE, installed = installed)
  expect_equal(sort(result), "pkgC")
})

