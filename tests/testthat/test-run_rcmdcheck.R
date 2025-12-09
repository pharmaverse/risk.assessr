test_that("running rcmd check for test package in tar file - no notes", {
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
  
  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE
  results <- list()
  
  if (package_installed == TRUE ) {
    
    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    
    testthat::expect_message(
      results$check <- run_rcmdcheck(pkg_source_path, rcmdcheck_args),
      glue::glue("rcmdcheck for {basename(pkg_source_path)} passed"),
      fixed = TRUE
    )
    
    testthat::expect_identical(length(results$check$res_check), 21L)
    
    testthat::expect_true(checkmate::check_class(results$check$res_check, "rcmdcheck"))
    
    testthat::expect_true(!is.na(results$check$res_check$test_output))
    
    testthat::expect_true(checkmate::test_numeric(results$check$check_score))
    
    testthat::expect_gte(results$check$check_score, 0)
    
    # Clean up
    withr::defer(unlink(pkg_source_path, recursive = TRUE))  # Test directory cleanup
    
    # Attempt to unload the namespace without checking installed.packages()
    try(unloadNamespace("test.package.0001"), silent = TRUE)
  }
})

test_that("running rcmd check for test package in tar file - 1 note 1 warning", {
  skip_on_cran()
  
  result <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  skip_if(
    grepl("Timeout of 60 seconds was reached", result$message) ||
      grepl("cannot open URL", result$message),
    message = paste("Skipping test because CRAN is not available:", result$message)
  )
  
  
  check_type <- "2"
  
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
  
  # set up package
  install_list <- set_up_pkg(dp, check_type)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE
  results <- list()
  
  if (package_installed == TRUE ) {
    
    
    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    
    testthat::expect_message(
      results$check <- run_rcmdcheck(pkg_source_path, rcmdcheck_args),
      glue::glue("rcmdcheck for {basename(pkg_source_path)} passed with warnings and/or notes"),
      fixed = TRUE
    )
    
    
    testthat::expect_identical(length(results$check$res_check), 21L)
    
    testthat::expect_true(checkmate::check_class(results$check$res_check, "rcmdcheck"))
    
    testthat::expect_true(!is.na(results$check$res_check$test_output))
    
    testthat::expect_true(checkmate::check_list(results$check$res_check$test_output))
    
    testthat::expect_true(checkmate::test_numeric(results$check$check_score))
    
    testthat::expect_gte(results$check$check_score, 0)
    
    # Clean up
    withr::defer(unlink(pkg_source_path, recursive = TRUE))  # Test directory cleanup
    
    # Attempt to unload the namespace without checking installed.packages()
    try(unloadNamespace("test.package.0002"), silent = TRUE)
    
  }
  
})

test_that("running rcmd check for test package in tar file - 1 note 1 error", {
  skip_on_cran() 
  
  result <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  skip_if(
    grepl("Timeout of 60 seconds was reached", result$message) ||
      grepl("cannot open URL", result$message),
    message = paste("Skipping test because CRAN is not available:", result$message)
  )
  
  
  check_type <- "2"
  
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
  
  # set up package
  install_list <- set_up_pkg(dp, check_type)
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE
  results <- list()
  
  if (package_installed == TRUE ) {
    
    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    
    testthat::expect_message(
      results$check <- run_rcmdcheck(pkg_source_path, rcmdcheck_args),
      glue::glue("rcmdcheck for {basename(pkg_source_path)} failed"),
      fixed = TRUE
    )
    
    testthat::expect_identical(length(results$check$res_check), 21L)
    
    testthat::expect_true(checkmate::check_class(results$check$res_check, "rcmdcheck"))
    
    testthat::expect_true(checkmate::check_list(results$check$res_check$test_output))
    
    testthat::expect_true(checkmate::test_numeric(results$check$check_score))
    
    testthat::expect_equal(results$check$check_score, 0)
    
    # Clean up
    withr::defer(unlink(pkg_source_path, recursive = TRUE))  # Test directory cleanup
    
    # Attempt to unload the namespace without checking installed.packages()
    try(unloadNamespace("test.package.0003"), silent = TRUE)
    
  }
})


test_that("running rcmd check for test package - error handling", {
  skip_on_cran()
  
  result <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  
  skip_if(
    grepl("Timeout of 60 seconds was reached", result$message) ||
      grepl("cannot open URL", result$message),
    message = paste("Skipping test because CRAN is not available:", result$message)
  )
  
  
  check_type <- "2"
  
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
  
  # set up package
  install_list <- set_up_pkg(dp, check_type)
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE
  results <- list()
  
  if (package_installed == TRUE ) {
    
    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    
    testthat::expect_message(
      results$check <- run_rcmdcheck(pkg_source_path, rcmdcheck_args),
      glue::glue("rcmdcheck for {basename(pkg_source_path)} failed"),
      fixed = TRUE
    )
    
    results <- list()
    results$check <- run_rcmdcheck(pkg_source_path, rcmdcheck_args)
    testthat::expect_identical(results$check$check_score, 0)
    testthat::expect_false(is.null(results$check$res_check$errors))
    testthat::expect_true(length(nzchar(results$check$res_check$errors)) > 0)
    
    # Clean up
    withr::defer(unlink(pkg_source_path, recursive = TRUE))  # Test directory cleanup
    
    # Attempt to unload the namespace without checking installed.packages()
    try(unloadNamespace("test.package.0003"), silent = TRUE)
  }
})
