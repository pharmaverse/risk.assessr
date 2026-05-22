# assess_pkg_r_package is a deprecated wrapper around risk_assess_pkg.
# Tests verify it forwards arguments correctly and shows deprecation.

test_that("assess_pkg_r_package forwards to risk_assess_pkg and shows deprecation", {
  captured <- new.env(parent = emptyenv())
  mockery::stub(assess_pkg_r_package, "risk_assess_pkg", function(path = NULL, package = NULL, version = NA, repos = getOption("repos")) {
    captured$path <- path
    captured$package <- package
    captured$version <- version
    captured$repos <- repos
    "mock-result"
  })

  expect_warning(res <- assess_pkg_r_package("somepkg", version = "1.2.3", repos = c(CRAN = "https://cloud.r-project.org")), "deprecated")
  expect_equal(res, "mock-result")
  expect_null(captured$path)
  expect_equal(captured$package, "somepkg")
  expect_equal(captured$version, "1.2.3")
  expect_equal(captured$repos, c(CRAN = "https://cloud.r-project.org"))
})

test_that("assess_pkg_r_package passes defaults correctly", {
  captured <- new.env(parent = emptyenv())
  mockery::stub(assess_pkg_r_package, "risk_assess_pkg", function(path = NULL, package = NULL, version = NA, repos = getOption("repos")) {
    captured$package <- package
    captured$version <- version
    captured$repos <- repos
    NULL
  })

  expect_warning(assess_pkg_r_package("mypkg"), "deprecated")
  expect_equal(captured$package, "mypkg")
  expect_identical(captured$version, NA)
  expect_equal(captured$repos, getOption("repos"))
})
