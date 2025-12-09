test_that("running coverage for created package in tar file with no notes", {
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0001_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {
    
    timeout = Inf
    coverage_list <- run_covr(pkg_source_path, timeout) 
    
    testthat::expect_true(checkmate::test_numeric(coverage_list$filecoverage))
    
    testthat::expect_equal(coverage_list$totalcoverage, 100)
    
    testthat::expect_true(!is.na(coverage_list$totalcoverage))
  }
})
