
test_that("cran_packages returns a matrix with expected structure", {
  skip_on_cran()
  pkgs <- cran_packages()
  
  expect_true(is.matrix(pkgs))
  expect_true("Package" %in% colnames(pkgs))
  expect_true(all(rownames(pkgs) %in% pkgs[, "Package"]))
})

test_that("cran_packages returns consistent results (memoised)", {
  skip_on_cran()
  pkgs1 <- cran_packages()
  Sys.sleep(1) # simulate time passing
  pkgs2 <- cran_packages()
  
  expect_identical(pkgs1, pkgs2)
})
