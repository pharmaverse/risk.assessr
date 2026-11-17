test_that("cran_packages returns a matrix with expected structure", {
  skip_on_cran()
  fake_rds <- matrix(
    c("pkgA", "1.0.0", "pkgB", "2.0.0"),
    nrow = 2, byrow = TRUE,
    dimnames = list(NULL, c("Package", "Version"))
  )
  mockery::stub(cran_packages, "utils::download.file", function(...) invisible(0L))
  mockery::stub(cran_packages, "readRDS", function(...) fake_rds)
  pkgs <- cran_packages(cache = FALSE)
  
  expect_true(is.matrix(pkgs))
  expect_true("Package" %in% colnames(pkgs))
  expect_identical(rownames(pkgs), c("pkgA", "pkgB"))
  expect_true(all(rownames(pkgs) %in% pkgs[, "Package"]))
})

test_that("cran_packages() caches across calls within the timeout window", {
  skip_on_cran()
  fake_rds <- matrix(
    c("pkgA", "1.0.0", "pkgB", "2.0.0"),
    nrow = 2, byrow = TRUE,
    dimnames = list(NULL, c("Package", "Version"))
  )
  download_calls <- 0L
  mockery::stub(cran_packages, "utils::download.file", function(...) {
    download_calls <<- download_calls + 1L
    invisible(0L)
  })
  mockery::stub(cran_packages, "readRDS", function(...) fake_rds)
  p1 <- cran_packages()
  p2 <- cran_packages()
  expect_identical(p1, p2)
})
