test_that("running coverage for created package in tar file with no notes", {
  skip_on_cran()
  
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
  
    testthat::expect_message(
      covr_list <- run_coverage(pkg_source_path),
      glue::glue("code coverage for {basename(pkg_source_path)} successful"),
      fixed = TRUE
    )
    
    # add total coverage to results
    results$covr <- covr_list$total_cov
    
    testthat::expect_true(checkmate::test_numeric(results$covr))
    
    testthat::expect_equal(results$covr, 1)
  } else {
    message(glue::glue("cannot run coverage test for {basename(pkg_source_path)}"))
} 

})

test_that("running coverage for created package in tar file with 1 note 1 warning", {
  
  skip_on_cran()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0002_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {
    
    testthat::expect_message(
      covr_list <- run_coverage(pkg_source_path),
      glue::glue("code coverage for {basename(pkg_source_path)} successful"),
      fixed = TRUE
    )
    
    # add total coverage to results
    results$covr <- covr_list$total_cov
    
    testthat::expect_true(checkmate::test_numeric(results$covr))
    
    testthat::expect_equal(results$covr, 1)
  } else {
    message(glue::glue("cannot run coverage test for {basename(pkg_source_path)}"))
  } 

})  

test_that("running coverage for created package in tar file with 1 note 1 error", {
  skip_on_cran()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0003_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {
    
    testthat::expect_message(
      covr_list <- run_coverage(pkg_source_path),
      glue::glue("R coverage for {basename(pkg_source_path)} failed"),
      fixed = TRUE
    )
    
    # add total coverage to results
    results$covr <- covr_list$total_cov
    
    testthat::expect_true(checkmate::test_numeric(results$covr))
    
    testthat::expect_true(is.na(results$covr))
  } else {
    message(glue::glue("cannot run coverage test for {basename(pkg_source_path)}"))
  } 
  
})  

test_that("running coverage for created package in tar file with no tests", {
  skip_on_cran()
 
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0004_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {
    
    covr_list <- run_coverage(pkg_source_path)
    
    # add total coverage to results
    results$covr <- covr_list$total_cov
    
    testthat::expect_true(checkmate::test_numeric(results$covr))
    
    testthat::expect_equal(results$covr, 0)
    
    testthat::expect_true(!is.na(results$covr))
    
    testthat::expect_equal(covr_list$res_cov$coverage$totalcoverage, 0)
    
  } else {
    message(glue::glue("cannot run coverage test for {basename(pkg_source_path)}"))
  } 
  
}) 

test_that("running coverage for created package in tar file with no functions", {
  skip_on_cran()
  dp <- system.file("test-data", "test.package.0005_0.1.0.tar.gz",
                    package = "risk.assessr")
  
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  if (package_installed == TRUE ) {
    
    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    
    
    testthat::expect_message(
      {
        covr_list <- run_coverage(pkg_source_path)
      }
    )
    
    # add total coverage to results
    results$covr <- covr_list$total_cov
    
    testthat::expect_true(checkmate::test_numeric(results$covr))
    
    testthat::expect_true(checkmate::test_numeric(covr_list$res_cov$coverage$totalcoverage))
    
  } else {
    message(glue::glue("cannot run coverage test for {basename(pkg_source_path)}"))
  } 
  
})

test_that("run_coverage handles errors in coverage_list correctly", {
  # Create a temporary package source path that will cause an error
  temp_pkg_path <- tempfile()
  dir.create(temp_pkg_path)
  
  # Create a dummy DESCRIPTION file to make it look like an R package
  writeLines("Package: tempPkg\nVersion: 0.1.0\n", file.path(temp_pkg_path, "DESCRIPTION"))
  
  # Run the coverage function with the temporary package path
  result <- run_coverage(temp_pkg_path, timeout = 1)
  
  # Check that the coverage_list contains NA values indicating an error
  expect_true(is.na(result$res_cov$coverage$filecoverage))
  expect_true(is.na(result$res_cov$coverage$totalcoverage))
  
  # Check that the errors field is not NA
  expect_false(is.null(result$res_cov$errors))
})

test_that("run_coverage captures all messages", {
  # Mock the run_covr function to simulate different scenarios
  mock_run_covr <- function(path, timeout) {
    if (path == "no_testable_functions") {
      return(list(filecoverage = logical(0), totalcoverage = NaN))
    } else if (path == "nan_total_coverage") {
      return(list(filecoverage = list(), totalcoverage = NaN))
    } else if (path == "successful_coverage") {
      return(list(filecoverage = list(), totalcoverage = 80))
    } else {
      stop("Unexpected path")
    }
  }
  
  # Use with_mocked_bindings to temporarily replace the run_covr function with the mock
  with_mocked_bindings(
    run_covr = mock_run_covr,
    {
      # Test case: No testable functions found
      messages <- capture_messages(run_coverage("no_testable_functions"))
      expect_true(any(grepl("running code coverage for no_testable_functions", messages)))
      expect_true(any(grepl("R coverage for no_testable_functions had notes: no testable functions found", messages)))
      
      # # Test case: Total coverage returned NaN
      messages <- capture_messages(run_coverage("nan_total_coverage"))
      expect_true(any(grepl("running code coverage for nan_total_coverage", messages)))
      expect_true(any(grepl("code coverage for nan_total_coverage unsuccessful", messages)))
      expect_true(any(grepl("R coverage for nan_total_coverage failed. Read in the covr output to see what went wrong:", messages)))
      
      # Test case: Successful coverage
      messages <- capture_messages(run_coverage("successful_coverage"))
      expect_true(any(grepl("running code coverage for successful_coverage", messages)))
    }
  )
})

