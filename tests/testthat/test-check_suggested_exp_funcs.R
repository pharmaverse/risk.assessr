
test_that("check_suggested_exp_funcs returns 2 matches", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz", 
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  package_installed <- 
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
  
    pkg_name <- "here"
    
    result <- check_suggested_exp_funcs(pkg_name, 
                                        pkg_source_path, 
                                        test_deps)
    
    expect_true(all(!is.na(result$source)))
    expect_true(all(is.na(result$targeted_package)))
    expect_true(all(!is.na(result$message)))
  }
})

test_that("check_suggested_exp_funcs returns matches messages for S3 functions", {
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)

  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0009_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)

  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args


  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE

  if (package_installed == TRUE ) {

    rcmdcheck_args$path <- pkg_source_path
    pkg_name <- "test.package.0009"

    #set up deps_df for this package
    package <- c("magrittr", "checkmate",
                 "testthat", "dplyr"
    )
    type <- c("Imports", "Suggests", "Suggests",
              "Suggests"
    )
    deps_df <- data.frame(package, type)


    result <- check_suggested_exp_funcs(pkg_name,
                                        pkg_source_path,
                                        deps_df)

    expect_equal(nrow(result), 4L)

    test_that("Messages are correct for S3 function", {
      expect_true(all(grepl("Please check if the targeted package should be in Imports", result$message)))
    })
  }
})

test_that("check_suggested_exp_funcs returns matches messages for S3 functions", {
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)

  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0009_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)

  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args


  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE

  if (package_installed == TRUE ) {

    rcmdcheck_args$path <- pkg_source_path
    pkg_name <- "test.package.0009"

    #set up deps_df for this package
    package <- c("magrittr", "checkmate",
                 "testthat", "dplyr"
    )
    type <- c("Imports", "Suggests", "Suggests",
              "Suggests"
    )
    deps_df <- data.frame(package, type)


    result <- check_suggested_exp_funcs(pkg_name,
                                        pkg_source_path,
                                        deps_df)

    expect_equal(nrow(result), 4L)

    test_that("Messages are correct for S3 function", {
      expect_true(all(grepl("Please check if the targeted package should be in Imports", result$message)))
    })
  }
})

test_that("check_suggested_exp_funcs returns matches messages for S4 functions", {
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0010_0.1.0.tar.gz", 
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
  package_installed <- 
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    
    rcmdcheck_args$path <- pkg_source_path
    pkg_name <- "test.package.0010"
    
    #set up deps_df for this package
    package <- c("checkmate",
                 "testthat", "methods"
    )
    type <- c("Suggests", "Suggests",
              "Suggests"
    ) 
    deps_df <- data.frame(package, type)
    
    
    result <- check_suggested_exp_funcs(pkg_name, 
                                        pkg_source_path, 
                                        deps_df)
    
    expect_equal(nrow(result), 1L)
    
    test_that("Messages are correct for S4 function", {
      expect_true(all(grepl("Please check if the targeted package should be in Imports", result$message)))
    })
  }
})

test_that("get_exports works correctly with R6 functions", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0011_0.1.0.tar.gz", 
                         package = "risk.assessr")
  dp <- tempfile(fileext = ".tar.gz")
  file.copy(dp_orig, dp)
  
  # Defer cleanup of copied tarball
  withr::defer(unlink(dp), envir = parent.frame())
  
  # Defer cleanup of unpacked source directory
  withr::defer(unlink(pkg_source_path, recursive = TRUE, force = TRUE),
               envir = parent.frame())
  
  # set up package
  install_list <- risk.assessr::set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  
  # install package locally to ensure test works
  package_installed <-
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    
    rcmdcheck_args$path <- pkg_source_path
    
    pkg_name <- "test.package.0011"
    
    #set up deps_df for this package
    package <- c("mockery", "testthat", "checkmate",
                 "cli", "fastmap", "rlang", "R6"
    )
    type <- c("Imports", "Suggests", "Suggests",
              "Suggests", "Suggests", "Suggests", "Suggests"
    ) 
    deps_df <- data.frame(package, type)
    
    result <- check_suggested_exp_funcs(pkg_name, 
                                        pkg_source_path, 
                                        deps_df)
    
    expect_equal(nrow(result), 1L)
    
    expect_true(all(!is.na(result$source)))
    expect_true(all(!is.na(result$message)))
    test_that("Messages are correct for R6 function", {
      expect_true(all(grepl("Please check if the targeted package should be in Imports", result$message)))
    })
  }
})

test_that("check_suggested_exp_funcs returns no exported functions message", {
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
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args
  
  # install package locally to ensure test works
  package_installed <- 
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
  
    pkg_name <- "test.package.0005"
    
    #set up deps_df for this package
    package <- c("magrittr", "checkmate",
                 "testthat", "dplyr"
    )
    type <- c("Imports", "Suggests", "Suggests",
              "Suggests"
    ) 
    deps_df <- data.frame(package, type)
    
    
    result <- check_suggested_exp_funcs(pkg_name, 
                                        pkg_source_path, 
                                        deps_df)
    
    expect_equal(nrow(result), 1L)
    
    expect_true(all(!is.na(result$source)))
    expect_true(all(!is.na(result$message)))
    expect_equal(result$message, "No exported functions from Suggested packages in the DESCRIPTION file")
  }
})

test_that("check_suggested_exp_funcs returns No R folder found in the package source path message", {
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0006_0.1.0.tar.gz", 
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
  package_installed <- 
    install_package_local(pkg_source_path)
  package_installed <- TRUE
  
  if (package_installed == TRUE ) {
    pkg_name <- "test.package.0006"
    
    #set up deps_df for this package
    package <- c("magrittr", "checkmate",
                 "testthat", "dplyr"
    )
    type <- c("Imports", "Suggests", "Suggests",
              "Suggests"
    ) 
    deps_df <- data.frame(package, type)
    
    
    result <- check_suggested_exp_funcs(pkg_name, 
                                        pkg_source_path, 
                                        deps_df)
    
    expect_equal(nrow(result), 1L)
    
    expect_true(all(!is.na(result$source)))
    expect_true(all(!is.na(result$message)))
    testthat::expect_message(
      result <- check_suggested_exp_funcs(pkg_name, 
                                          pkg_source_path, 
                                          deps_df),
      glue::glue("No R folder found in the package source path"),
      fixed = TRUE
    )
  }
})


test_that("check_suggested_exp_funcs handles NULL suggested_exp_func correctly", {

  mock_contains_r_folder <- function(...) TRUE

mock_get_exports <- function(...) {
  data.frame(
    exported_function = c("func1", "func2", "func3"),
    function_body = c("body1", "body2", "body3")
  )
}

  mock_get_suggested_exp_funcs <- function(...) NULL
  # mock_get_function_details <- function(...) data.frame(details = "mocked details")

  pkg_name <- "target_pkg"
  pkg_source_path <- "dummy_path"
  suggested_deps <- data.frame(package = c("pkgA", "pkgB"))

  testthat::local_mocked_bindings(
    `contains_r_folder` = mock_contains_r_folder,
    `get_exports` = mock_get_exports,
    `get_suggested_exp_funcs` = mock_get_suggested_exp_funcs
  #  `get_function_details` = mock_get_function_details
  )

  result <- check_suggested_exp_funcs(pkg_name, pkg_source_path, suggested_deps)

  expect_true(any(grepl("No Suggested packages in the DESCRIPTION file", result$message)))
})
  

# Create toy datasets for testing create_items_matched
extracted_functions <- dplyr::tibble(
  suggested_function = c("dplyr::mutate", "stringr::str_detect", "ggplot2::ggplot", "base::mean")
)

suggested_exp_func <- dplyr::tibble(
  package = c("dplyr", "stringr"),
  exported_functions = c("mutate", "str_detect")
)

# Expected output
expected_output <- dplyr::tibble(
  suggested_function = c("dplyr::mutate", "stringr::str_detect")
)

# Test the function
test_that("create_items_matched works correctly", {
  result <- create_items_matched(extracted_functions, suggested_exp_func) %>% 
    dplyr::ungroup() # Convert to regular tibble
  expect_equal(result, expected_output)
})

# Create toy datasets for process_items_matched testing
items_matched <- dplyr::tibble(
  source = c("file1", "file2", "file3"),
  suggested_function = c("dplyr::mutate", "stringr::str_detect", "base::mean")
)

suggested_exp_func <- dplyr::tibble(
  package = c("dplyr", "stringr", "base"),
  functions = c("mutate", "str_detect", "mean")
)

# Expected output
expected_output <- dplyr::tibble(
  source = c("file1", "file2", "file3"),
  suggested_function = c("mutate", "str_detect", "mean"),
  targeted_package = c("dplyr", "stringr", "base"),
  message = rep("Please check if the targeted package should be in Imports", 3)
)

# Test the function
test_that("process_items_matched works correctly", {
  result <- process_items_matched(items_matched, suggested_exp_func)
  expect_equal(result, expected_output)
})

test_that("check_suggested_exp_funcs handles empty suggested_deps", {
  # Mock data
  pkg_name <- "testpkg"
  pkg_source_path <- "path/to/testpkg"
  suggested_deps <- data.frame() # Empty data frame
  
  # Mock functions
  mock_contains_r_folder <- mockery::mock(TRUE)
  mock_get_exports <- mockery::mock(data.frame(exported_function = character()))
  mock_get_function_details <- mockery::mock(data.frame())
  mock_get_suggested_exp_funcs <- mockery::mock(data.frame())
  mock_create_items_matched <- mockery::mock(data.frame())
  mock_process_items_matched <- mockery::mock(data.frame())
  
  # Replace the actual functions with mocks
  mockery::stub(check_suggested_exp_funcs, "risk.assessr::contains_r_folder", mock_contains_r_folder)
  mockery::stub(check_suggested_exp_funcs, "risk.assessr::get_exports", mock_get_exports)
  # mockery::stub(check_suggested_exp_funcs, "get_function_details", mock_get_function_details)
  mockery::stub(check_suggested_exp_funcs, "risk.assessr::get_suggested_exp_funcs", mock_get_suggested_exp_funcs)
  mockery::stub(check_suggested_exp_funcs, "create_items_matched", mock_create_items_matched)
  mockery::stub(check_suggested_exp_funcs, "process_items_matched", mock_process_items_matched)
  
  # Call the function
  result <- check_suggested_exp_funcs(pkg_name, pkg_source_path, suggested_deps)
  
  # Check the result
  expect_equal(result$message, "No Imports or Suggested packages in the DESCRIPTION file")
  expect_true(is.na(result$suggested_function))
  expect_true(is.na(result$targeted_package))
})
