test_that("running assess_pkg for test package in tar file - no notes", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)

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

  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links= NULL))
  }

  mockery::stub(assess_pkg, "get_host_package", mock_get_host_package)

  mock_unit_test <- function(pkg_source_path) {
    return(list(
      has_testthat = TRUE,
      has_snaps = TRUE,
      n_golden_tests = 100,
      n_test_files = 100
    ))
  }

  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", mock_unit_test)

  mock_check_and_fetch_cran_package <- function(pkg_name, pkg_ver) {
    return(list(
      all_versions = list(
        list(version = "0.1.0", date = "2021-01-01"), # actual package version
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01")
    ))
  }

  mockery::stub(assess_pkg, "check_and_fetch_cran_package", mock_check_and_fetch_cran_package)

  mock_get_risk_analysis <- function(pkg_name) {
    return(list())
  }

  mockery::stub(assess_pkg, "get_risk_analysis", mock_get_risk_analysis)


  # set up package
  install_list <- set_up_pkg(dp)

  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args

  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE

  if (package_installed == TRUE ) {

    rcmdcheck_args$path <- pkg_source_path
    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)

    testthat::expect_identical(length(assess_package), 5L)
    
    testthat::expect_true(checkmate::check_class(assess_package, "list"))
    
    testthat::expect_identical(length(assess_package$results), 30L)
    
    testthat::expect_true(!is.na(assess_package$results$pkg_name))
    
    testthat::expect_true(!is.na(assess_package$results$pkg_version))
    
    testthat::expect_true(!is.na(assess_package$results$pkg_source_path))
    
    testthat::expect_true(!is.na(assess_package$results$date_time))
    
    testthat::expect_true(!is.na(assess_package$results$executor))
    
    testthat::expect_true(!is.na(assess_package$results$sysname))
    
    testthat::expect_true(!is.na(assess_package$results$version))
    
    testthat::expect_true(!is.na(assess_package$results$release))
    
    testthat::expect_true(!is.na(assess_package$results$machine))
    
    testthat::expect_true(!is.na(assess_package$results$comments))
    
    testthat::expect_null(assess_package$results$has_bug_reports_url)
    
    testthat::expect_true(!is.na(assess_package$results$license))
    
    testthat::expect_true(!is.na(assess_package$results$size_codebase))
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$size_codebase))
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$check))
    
    testthat::expect_gte(assess_package$results$check, 0)
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$covr))
    
    testthat::expect_gte(assess_package$results$covr, 0.7)

    testthat::expect_identical(length(assess_package$covr_list), 2L)
    
    testthat::expect_true(!is.na(assess_package$covr_list$res_cov$name))
    
    testthat::expect_identical(length(assess_package$covr_list$res_cov$coverage), 2L)
    
    testthat::expect_identical(length(assess_package$tm), 3L)
    
    testthat::expect_identical(length(assess_package$tm_list$tm), 9L)
    
    testthat::expect_true(!is.na(assess_package$tm_list$tm$exported_function))
    
    testthat::expect_true(!is.na(assess_package$tm_list$tm$code_script))
    
    testthat::expect_true(!is.na(assess_package$tm_list$tm$documentation))
    
    testthat::expect_true(!is.na(assess_package$tm_list$tm$coverage_percent))
    
    # high risk tm tests
    expect_true(is.list(assess_package$tm_list$coverage$high_risk))
    expect_identical(assess_package$tm_list$coverage$high_risk$pkg_name, "test.package.0001")
    expect_true(is.list(assess_package$tm_list$coverage$high_risk$coverage))
    expect_identical(assess_package$tm_list$coverage$high_risk$coverage$filecoverage, 0)
    expect_identical(assess_package$tm_list$coverage$high_risk$coverage$totalcoverage, 0)
    expect_true(is.na(assess_package$tm_list$coverage$high_risk$errors))
    expect_true(is.na(assess_package$tm_list$coverage$high_risk$notes))
    
    # medium risk tm tests
    expect_true(is.list(assess_package$tm_list$coverage$medium_risk))
    expect_identical(assess_package$tm_list$coverage$medium_risk$pkg_name, "test.package.0001")
    expect_true(is.list(assess_package$tm_list$coverage$medium_risk$coverage))
    expect_identical(assess_package$tm_list$coverage$medium_risk$coverage$filecoverage, 0)
    expect_identical(assess_package$tm_list$coverage$medium_risk$coverage$totalcoverage, 0)
    expect_true(is.na(assess_package$tm_list$coverage$medium_risk$errors))
    expect_true(is.na(assess_package$tm_list$coverage$medium_risk$notes))
    
    # low risk tm tests
    testthat::expect_equal(nrow(assess_package$tm_list$coverage$low_risk), 1)
    testthat::expect_true(all(c("exported_function", "class", "function_type", "function_body",
                                "where", "code_script", "documentation", "description",
                                "coverage_percent") %in% names(assess_package$tm_list$coverage$low_risk)))
    
    testthat::expect_identical(assess_package$tm_list$coverage$low_risk$exported_function[1], "myfunction")
    testthat::expect_true(is.na(assess_package$tm_list$coverage$low_risk$class[1]))
    testthat::expect_identical(assess_package$tm_list$coverage$low_risk$function_type[1], "regular function")
    testthat::expect_true(!is.na(assess_package$tm_list$coverage$low_risk$function_body[1]))
    testthat::expect_true(grepl("^test\\.package", assess_package$tm_list$coverage$low_risk$where[1]))
    testthat::expect_true(grepl("^R/", assess_package$tm_list$coverage$low_risk$code_script[1]))
    testthat::expect_identical(assess_package$tm_list$coverage$low_risk$documentation[1], "myfunction.Rd")
    testthat::expect_type(assess_package$tm_list$coverage$low_risk$coverage_percent[1], "double")
    
    testthat::expect_identical(length(assess_package$check_list), 2L)
    
    testthat::expect_identical(length(assess_package$check_list$res_check), 21L)
    
    testthat::expect_true(!is.na(assess_package$check_list$res_check$platform))
    
    testthat::expect_true(!is.na(assess_package$check_list$res_check$package))
    
    testthat::expect_identical(length(assess_package$check_list$res_check$test_output), 1L)
    
    testthat::expect_true(!is.na(assess_package$check_list$res_check$test_output$testthat))
    
    testthat::expect_true(all(sapply(assess_package$check_list$res_check$session_info$platform,
                                     function(x) !is.null(x) && x != "")))

    testthat::expect_true("created_at" %in% names(assess_package$results$github_data))
    testthat::expect_true("stars" %in% names(assess_package$results$github_data))
    testthat::expect_true("forks" %in% names(assess_package$results$github_data))
    testthat::expect_true("date" %in% names(assess_package$results$github_data))
    testthat::expect_true("recent_commits_count" %in% names(assess_package$results$github_data))

    testthat::expect_true("maintainer" %in% names(assess_package$results$author))
    testthat::expect_true("funder" %in% names(assess_package$results$author))
    testthat::expect_true("authors" %in% names(assess_package$results$author))

    testthat::expect_true("github_links" %in% names(assess_package$results$host))
    testthat::expect_true("cran_links" %in% names(assess_package$results$host))
    testthat::expect_true("internal_links" %in% names(assess_package$results$host))
    testthat::expect_true("bioconductor_links" %in% names(assess_package$results$host))

    testthat::expect_true("all_versions" %in% names(assess_package$results$version_info))
    testthat::expect_true("last_version" %in% names(assess_package$results$version_info))
    testthat::expect_true("difference_version_months" %in% names(assess_package$results$version_info))
    testthat::expect_true("total_download" %in% names(assess_package$results$download))

    testthat::expect_true("last_month_download" %in% names(assess_package$results$download))
    
    diff_months <- assess_package$results$version_info$difference_version_months
    expect_equal(diff_months, 24)
  }
})



Sys.setenv("R_TESTS" = "")
library(testthat)

test_that("running assess_pkg for test package in tar file - no exports", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)

  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0005_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links= NULL))
  }

  mockery::stub(assess_pkg, "get_host_package", mock_get_host_package)

  mock_unit_test <- function(pkg_source_path) {
    return(list(
      has_testthat = TRUE,
      has_snaps = TRUE,
      n_golden_tests = 100,
      n_test_files = 100
    ))
  }

  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", mock_unit_test)

  mock_check_and_fetch_cran_package <- function(pkg_name, pkg_ver) {
    return(list(
      all_versions = list(
        list(version = "0.1.0", date = "2023-01-01"), # actual package version
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01")
    ))
  }

  mockery::stub(assess_pkg, "check_and_fetch_cran_package", mock_check_and_fetch_cran_package)

  mock_get_risk_analysis <- function(pkg_name) {
    return(list())
  }

  mockery::stub(assess_pkg, "get_risk_analysis", mock_get_risk_analysis)


  # set up package
  install_list <- set_up_pkg(dp)

  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args

  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE

  if (package_installed == TRUE ) {

    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)

    testthat::expect_identical(length(assess_package), 5L)
    
    testthat::expect_true(checkmate::check_class(assess_package, "list"))
    
    testthat::expect_identical(length(assess_package$results), 30L)
    
    testthat::expect_true(!is.na(assess_package$results$pkg_name))
    
    testthat::expect_true(!is.na(assess_package$results$pkg_version))
    
    testthat::expect_true(!is.na(assess_package$results$pkg_source_path))
    
    testthat::expect_true(!is.na(assess_package$results$date_time))
    
    testthat::expect_true(!is.na(assess_package$results$executor))
    
    testthat::expect_true(!is.na(assess_package$results$sysname))
    
    testthat::expect_true(!is.na(assess_package$results$version))
    
    testthat::expect_true(!is.na(assess_package$results$release))
    
    testthat::expect_true(!is.na(assess_package$results$machine))
    
    testthat::expect_true(!is.na(assess_package$results$comments))
    
    testthat::expect_null(assess_package$results$has_bug_reports_url)
    
    testthat::expect_true(!is.na(assess_package$results$suggested_deps$source))
    
    testthat::expect_true(identical(assess_package$results$suggested_deps$message,
                                    "No exported functions from Suggested packages in the DESCRIPTION file"))
    
    testthat::expect_true(!is.na(assess_package$results$license))
    
    testthat::expect_true(!is.na(assess_package$results$size_codebase))
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$size_codebase))
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$check))
    
    testthat::expect_gte(assess_package$results$check, 0)
    
    testthat::expect_true(checkmate::test_numeric(assess_package$results$covr))
    
    testthat::expect_gte(assess_package$results$covr, 0)
    
    testthat::expect_identical(length(assess_package$covr_list), 2L)
    
    testthat::expect_true(!is.na(assess_package$covr_list$res_cov$name))
    
    testthat::expect_identical(length(assess_package$covr_list$res_cov$coverage), 2L)
    
    testthat::expect_identical(length(assess_package$tm_list), 4L)
    
    testthat::expect_identical(length(assess_package$tm_list$tm), 0L)
    
    expect_identical(assess_package$tm_list$coverage$filecoverage, 0)
    
    expect_identical(assess_package$tm_list$coverage$totalcoverage, 0)
    
    testthat::expect_identical(length(assess_package$check_list), 2L)
    
    testthat::expect_identical(length(assess_package$check_list$res_check), 21L)
    
    testthat::expect_true(!is.na(assess_package$check_list$res_check$platform))
    
    testthat::expect_true(!is.na(assess_package$check_list$res_check$package))
    
    testthat::expect_identical(length(assess_package$check_list$res_check$test_output), 0L)
    
    testthat::expect_true(is.null(assess_package$check_list$res_check$test_output$testthat))
    
    testthat::expect_true(all(sapply(assess_package$check_list$res_check$session_info$platform,
                                     function(x) !is.null(x) && x != "")))
    diff_months <- assess_package$results$version_info$difference_version_months
    expect_equal(diff_months, 0)
  }
})


test_that("running assess_pkg for test package with Config/build/clean-inst-doc: false", {
  skip_on_cran()

  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links= NULL))
  }

  mockery::stub(assess_pkg, "get_host_package", mock_get_host_package)

  mock_unit_test <- function(pkg_source_path) {
    return(list(
      has_testthat = TRUE,
      has_snaps = TRUE,
      n_golden_tests = 100,
      n_test_files = 100
    ))
  }

  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", mock_unit_test)

  mock_check_and_fetch_cran_package <- function(pkg_name, pkg_ver) {
    return(list(
      all_versions = list(
        list(version = "0.1.0", date = "2023-01-01"), # actual package version
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01")
    ))
  }

  mockery::stub(assess_pkg, "check_and_fetch_cran_package", mock_check_and_fetch_cran_package)

  mock_get_risk_analysis <- function(pkg_name) {
    return(list())
  }

  mockery::stub(assess_pkg, "get_risk_analysis", mock_get_risk_analysis)


  dp <- system.file("test-data", "test.package.0005_0.1.0.tar.gz",
                    package = "risk.assessr")

  # Check if the file exists before attempting to download
  if (!file.exists(dp)) {
    stop("The tar file does not exist at the specified path.")
  }

  # Create a temporary file to store the downloaded package
  file_name <- basename(dp) # Use the base name for temporary file
  temp_file <- file.path(tempdir(), file_name)

  # Copy the file to the temporary file instead of downloading it
  file.copy(dp, temp_file, overwrite = TRUE)

  # Verify that the copy was successful
  if (!file.exists(temp_file)) {
    stop("File copy failed: temporary file not found.")
  }

  # Run the function to modify the DESCRIPTION file
  modified_tar_file <- modify_description_file(temp_file)

  # Set up package
  install_list <- set_up_pkg(dp)

  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args

  if (package_installed == TRUE) {

    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)

    testthat::expect_true(checkmate::check_class(assess_package, "list"))
  }
})

test_that("running assess_pkg for test package fail suggest", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)

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

  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links= NULL))
  }

  mockery::stub(assess_pkg, "get_host_package", mock_get_host_package)

  mock_unit_test <- function(pkg_source_path) {
    return(list(
      has_testthat = TRUE,
      has_snaps = TRUE,
      n_golden_tests = 100,
      n_test_files = 100
    ))
  }

  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", mock_unit_test)

  mock_check_and_fetch_cran_package <- function(pkg_name, pkg_ver) {
    return(list(
      all_versions = list(
        list(version = "0.1.0", date = "2023-01-01"), # actual package version
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01")
    ))
  }

  mockery::stub(assess_pkg, "check_and_fetch_cran_package", mock_check_and_fetch_cran_package)

  mock_get_risk_analysis <- function(pkg_name) {
    return(list())
  }

  mockery::stub(assess_pkg, "get_risk_analysis", mock_get_risk_analysis)

  mock_check_suggested_exp_funcs <- function() {
    stop()
  }

  # Stub it to return an error
  mockery::stub(check_suggested_exp_funcs, "check_suggested_exp_funcs", mock_check_suggested_exp_funcs)

  # set up package
  install_list <- set_up_pkg(dp)

  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args

  # install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)
  package_installed <- TRUE

  if (package_installed == TRUE ) {

    rcmdcheck_args$path <- pkg_source_path
    assess_package <-assess_pkg(pkg_source_path, rcmdcheck_args)
    suggested_deps <- assess_package$results$suggested_deps

  }

  expected_values <- data.frame(
    source = "test.package.0001",
    suggested_function = 0,
    targeted_package = 0,
    message = "No exported functions from Suggested packages in the DESCRIPTION file",
    stringsAsFactors = FALSE
  )
  expect_equal(suggested_deps, expected_values)
})



test_that("assess_pkg handles errors in check_suggested_exp_funcs correctly", {
  skip_on_cran()
  # Set CRAN repository
  r <- getOption("repos")
  r["CRAN"] <- "http://cran.us.r-project.org"
  options(repos = r)

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

  mock_get_host_package <- function(pkg_name, pkg_ver, pkg_source_path) {
    return(list(cran_links = "CRAN", github_links = NULL, bioconductor_links = NULL, internal_links= NULL))
  }

  mockery::stub(assess_pkg, "get_host_package", mock_get_host_package)

  mock_unit_test <- function(pkg_source_path) {
    return(list(
      has_testthat = TRUE,
      has_snaps = TRUE,
      n_golden_tests = 100,
      n_test_files = 100
    ))
  }

  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", mock_unit_test)

  mock_check_and_fetch_cran_package <- function(pkg_name, pkg_ver) {
    return(list(
      all_versions = list(
        list(version = "0.1.0", date = "2023-01-01"), # actual package version
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01")
    ))
  }

  mockery::stub(assess_pkg, "check_and_fetch_cran_package", mock_check_and_fetch_cran_package)

  mock_get_risk_analysis <- function(pkg_name) {
    return(list())
  }

  mockery::stub(assess_pkg, "get_risk_analysis", mock_get_risk_analysis)


  # Mock check_suggested_exp_funcs to return an error
  mock_check_suggested_exp_funcs <- function() {
    stop("Mock error")
  }

  # Stub it to return an error
  mockery::stub(check_suggested_exp_funcs, "check_suggested_exp_funcs", mock_check_suggested_exp_funcs)

  # Set up package
  install_list <- set_up_pkg(dp)

  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args

  # Install package locally to ensure test works
  package_installed <- install_package_local(pkg_source_path)

  if (package_installed) {
    rcmdcheck_args$path <- pkg_source_path
    assess_package <- assess_pkg(pkg_source_path, rcmdcheck_args)
    suggested_deps <- assess_package$results$suggested_deps

    # Check the results
    expect_true("suggested_deps" %in% names(assess_package$results))
    expect_equal(nrow(suggested_deps), 1)
    expect_equal(suggested_deps$source, "test.package.0001")
    # expect_equal(suggested_deps$suggested_function, "Error in checking suggested functions")

    # Additional checks for covr column
    expect_true("covr" %in% names(assess_package$results))
    expect_equal(assess_package$results$covr, 1)
  }
})



test_that("assess_pkg handles error in check_suggested_exp_funcs via withCallingHandlers", {
 
  # Create a real temporary directory and DESCRIPTION file
  pkg_source_path <- withr::local_tempdir()
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  writeLines(c(
    "Package: mockpkg",
    "Version: 0.1.0",
    "Title: Mock Package",
    "Description: A mock package for testing.",
    "Authors@R: c(person(given = \"Mock\", family = \"Author\", role = c(\"aut\", \"cre\")))"
  ), desc_path)
  
  # Stub get_pkg_desc to return mock name/version
  mockery::stub(assess_pkg, "get_pkg_desc", function(path, fields) {
    list(Package = "mockpkg", Version = "0.1.0")
  })
  
  # Stub all other required functions to return minimal valid data
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) list(suggested_deps = NULL))
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = TRUE, has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", function(...) list(has_testthat = FALSE, has_testit = FALSE))
  mockery::stub(assess_pkg, "run_rcmdcheck", function(...) list(check_score = 1))
  mockery::stub(assess_pkg, "get_dependencies", function(...) list())
  mockery::stub(assess_pkg, "create_empty_tm", function(...) list())
  
  # Stub check_suggested_exp_funcs to throw an error caught by withCallingHandlers
  mockery::stub(assess_pkg, "check_suggested_exp_funcs", function(...) stop("Simulated error in inner handler"))
  
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  expect_message(
    assess_pkg(pkg_source_path, rcmdcheck_args),
    "No testthat or testit configuration"
  )
})

test_that("assess_pkg handles error via outer tryCatch block", {
 
  # Create a real temporary directory and DESCRIPTION file
  pkg_source_path <- withr::local_tempdir()
  desc_path <- file.path(pkg_source_path, "DESCRIPTION")
  writeLines(c(
    "Package: mockpkg",
    "Version: 0.1.0",
    "Title: Mock Package",
    "Description: A mock package for testing.",
    "Authors@R: c(person(given = \"Mock\", family = \"Author\", role = c(\"aut\", \"cre\")))"
  ), desc_path)
  
  # Stub get_pkg_desc to return mock name/version
  mockery::stub(assess_pkg, "get_pkg_desc", function(path, fields) {
    list(Package = "mockpkg", Version = "0.1.0")
  })
  
  # Stub all other required functions to return minimal valid data
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) list(suggested_deps = NULL))
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = TRUE, has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", function(...) list(has_testthat = FALSE, has_testit = FALSE))
  mockery::stub(assess_pkg, "run_rcmdcheck", function(...) list(check_score = 1))
  mockery::stub(assess_pkg, "get_dependencies", function(...) list())
  mockery::stub(assess_pkg, "create_empty_tm", function(...) list())
  
  # Stub withCallingHandlers to simulate an error that bypasses inner handler
  mockery::stub(assess_pkg, "withCallingHandlers", function(expr, ...) {
    stop("Simulated outer error")
  })
  
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  expect_message(
    assess_pkg(pkg_source_path, rcmdcheck_args),
    "An error occurred in checking suggested functions: Simulated outer error"
  )
})


test_that("assess_pkg follows Bioconductor path and records version/revdeps", {
  skip_on_cran()
  
  # Create a minimal real pkg structure
  pkg_source_path <- withr::local_tempdir()
  writeLines(c(
    "Package: mockbio",
    "Version: 1.0.0",                     # matches an entry below → difference months = 0
    "Title: Mock BioPkg",
    "Description: A mock package.",
    "Authors@R: person('A','B',role=c('aut','cre'))",
    "License: MIT"
  ), file.path(pkg_source_path, "DESCRIPTION"))
  dir.create(file.path(pkg_source_path, "R"), showWarnings = FALSE)
  writeLines("", file.path(pkg_source_path, "NAMESPACE"))
  
  # Minimal rcmdcheck args
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  # --- Stubs to force the Bioconductor branch and keep runtime tiny ---
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) {
    list(
      pkg_name = "mockbio", pkg_version = "1.0.0", pkg_source_path = pkg_source_path,
      date_time = Sys.time(), executor = "test", sysname = "Windows", version = "R",
      release = "0", machine = "x86", comments = "", suggested_deps = NULL
    )
  })
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = "MIT", has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", function(...) list(has_testthat = FALSE, has_testit = FALSE))
  mockery::stub(assess_pkg, "run_rcmdcheck", function(...) list(check_score = 1))
  mockery::stub(assess_pkg, "get_dependencies", function(...) list())
  mockery::stub(assess_pkg, "create_empty_tm", function(...) list())
  mockery::stub(assess_pkg, "get_pkg_author", function(...) list(maintainer = "A B", funder = NA, authors = "A B"))
  mockery::stub(assess_pkg, "get_pkg_license", function(...) "MIT")
  mockery::stub(assess_pkg, "get_host_package", function(pkg, ver, path) {
    list(cran_links = NULL, github_links = NULL, bioconductor_links = "bioc", internal_links = NULL)
  })
  mockery::stub(assess_pkg, "get_repo_owner", function(...) "owner")
  mockery::stub(assess_pkg, "get_github_data", function(...) list(created_at = NA, stars = 0, forks = 0, date = NA, recent_commits_count = 0))
  mockery::stub(assess_pkg, "get_cran_total_downloads", function(...) 0)
  # Bioconductor-specific stubs
  mockery::stub(assess_pkg, "fetch_bioconductor_releases", function() "<html/>")
  mockery::stub(assess_pkg, "parse_bioconductor_releases", function(html) list())  # not used by our next stub
  mockery::stub(assess_pkg, "get_bioconductor_package_url", function(pkg, ver, rel) {
    list(
      all_versions = list(
        list(version = "0.9.0", date = "2022-01-01"),
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01"),
      bioconductor_version_package = "3.17"
    )
  })
  mockery::stub(assess_pkg, "bioconductor_reverse_deps", function(pkg, version) c("pkgA", "pkgB"))
  mockery::stub(assess_pkg, "risk.assessr::get_session_dependencies", function(...) list())
  mockery::stub(assess_pkg, "get_risk_analysis", function(...) list())
  
  res <- assess_pkg(pkg_source_path, rcmdcheck_args)
  
  expect_true(is.list(res))
  expect_true("results" %in% names(res))
  expect_true("version_info" %in% names(res$results))
  expect_equal(res$results$version_info$bioconductor_version_package, "3.17")
  expect_equal(res$results$version_info$last_version$version, "1.0.0")
  # Version in DESCRIPTION == "1.0.0" → index matches → difference months 0
  expect_equal(res$results$version_info$difference_version_months, 0)
  # Revdeps populated from Bioconductor path:
  expect_equal(res$results$rev_deps, c("pkgA", "pkgB"))
})


test_that("assess_pkg Bioconductor path coerces empty reverse deps to 0", {
  skip_on_cran()
  
  pkg_source_path <- withr::local_tempdir()
  writeLines(c(
    "Package: mockbioempty",
    "Version: 1.0.0",
    "Title: Mock BioPkg Empty",
    "Description: A mock package.",
    "Authors@R: person('A','B',role=c('aut','cre'))",
    "License: MIT"
  ), file.path(pkg_source_path, "DESCRIPTION"))
  dir.create(file.path(pkg_source_path, "R"), showWarnings = FALSE)
  writeLines("", file.path(pkg_source_path, "NAMESPACE"))
  
  rcmdcheck_args <- list(timeout = Inf, args = c("--no-manual"), build_args = NULL, env = "mockenv", quiet = TRUE)
  
  mockery::stub(assess_pkg, "get_risk_metadata", function() list())
  mockery::stub(assess_pkg, "create_empty_results", function(...) list(suggested_deps = NULL))
  mockery::stub(assess_pkg, "doc_riskmetric", function(...) list(
    has_bug_reports_url = TRUE, license = "MIT", has_examples = TRUE,
    has_maintainer = TRUE, size_codebase = 10, has_news = TRUE,
    has_source_control = TRUE, has_vignettes = TRUE, has_website = TRUE,
    news_current = TRUE, export_help = TRUE
  ))
  mockery::stub(assess_pkg, "check_pkg_tests_and_snaps", function(...) list(has_testthat = FALSE, has_testit = FALSE))
  mockery::stub(assess_pkg, "run_rcmdcheck", function(...) list(check_score = 1))
  mockery::stub(assess_pkg, "get_dependencies", function(...) list())
  mockery::stub(assess_pkg, "create_empty_tm", function(...) list())
  mockery::stub(assess_pkg, "get_host_package", function(pkg, ver, path) {
    list(cran_links = NULL, github_links = NULL, bioconductor_links = "bioc", internal_links = NULL)
  })
  mockery::stub(assess_pkg, "fetch_bioconductor_releases", function() "<html/>")
  mockery::stub(assess_pkg, "parse_bioconductor_releases", function(html) list())
  mockery::stub(assess_pkg, "get_bioconductor_package_url", function(pkg, ver, rel) {
    list(
      all_versions = list(
        list(version = "1.0.0", date = "2023-01-01")
      ),
      last_version = list(version = "1.0.0", date = "2023-01-01"),
      bioconductor_version_package = "3.18"
    )
  })
  # Return empty to trigger the post-processing fallback to 0
  mockery::stub(assess_pkg, "bioconductor_reverse_deps", function(pkg, version) character(0))
  mockery::stub(assess_pkg, "risk.assessr::get_session_dependencies", function(...) list())
  mockery::stub(assess_pkg, "get_risk_analysis", function(...) list())
  
  res <- assess_pkg(pkg_source_path, rcmdcheck_args)
  
  expect_true(is.list(res))
  expect_true("results" %in% names(res))
  expect_equal(res$results$version_info$bioconductor_version_package, "3.18")
  expect_equal(res$results$version_info$difference_version_months, 0)
  # Empty reverse deps must be coerced to numeric 0
  expect_identical(res$results$rev_deps, 0)
})

