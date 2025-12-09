test_that("running tm for created package in tar file with no notes", {
  skip_on_cran()
  dp <- system.file("test-data", "stringr-1.5.1.tar.gz",
                    package = "risk.assessr")
  
  # set up package
  install_list <- set_up_pkg(dp)
  
  build_vignettes <- install_list$build_vignettes
  package_installed <- install_list$package_installed
  pkg_source_path <- install_list$pkg_source_path
  rcmdcheck_args <- install_list$rcmdcheck_args

  # Defer cleanup: remove test package from temp dirs
  withr::defer({
    unlink(pkg_source_path, recursive = TRUE, force = TRUE)
  })
  
  if (package_installed == TRUE ) {

    # setup parameters for running covr
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)

    covr_timeout <- Inf

    covr_list <- run_coverage(
      pkg_source_path,  # must use untarred package dir
      covr_timeout
    )

    tm_list <- create_traceability_matrix(pkg_name,
                                     pkg_source_path,
                                     covr_list$res_cov
                                     )
    
    testthat::expect_identical(length(tm_list), 3L)
    
    testthat::expect_identical(length(tm_list$tm), 9L)

    # Column to check
    column_name <- "exported_function"
    
    # Test to check if there are no missing values in the specified column
    testthat::expect_true(all(!is.na(tm_list$tm[[column_name]])))

    testthat::expect_true(checkmate::check_data_frame(tm_list$tm,
                                            col.names = "named")
    )

  } else {
    message(glue::glue("cannot run traceability matrix for {basename(pkg_source_path)}"))
  }

})


# The following test is commented out temporarily
# the test with devtools::test() but the problem is caused by
#  https://github.com/hadley/testthat/issues/144
# and https://github.com/r-lib/testthat/issues/86
test_that("running tm for created package in tar file with no tests", {
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

    # ensure path is set to package source path
    rcmdcheck_args$path <- pkg_source_path
    
    # setup parameters for running covr
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)

    covr_timeout <- Inf

    covr_list <- suppressMessages(run_coverage(
      pkg_source_path,  # must use untarred package dir
      covr_timeout)
    )

    tm_list <- create_traceability_matrix(pkg_name,
                                       pkg_source_path,
                                       covr_list$res_cov)

    testthat::expect_identical(length(tm_list), 3L)
    
    testthat::expect_identical(length(tm_list$tm), 9L)

    testthat::expect_true(checkmate::check_data_frame(tm_list$tm,
                                                      any.missing = TRUE))

    testthat::expect_true(checkmate::check_data_frame(tm_list$tm,
                                                      col.names = "named")
    )

    testthat::expect_equal(covr_list$total_cov, 0)

    testthat::expect_equal(covr_list$res_cov$coverage$totalcoverage, 0)

  } else {
    message(glue::glue("cannot run traceability matrix for {basename(pkg_source_path)}"))
  }

})

test_that("running tm for created package in tar file with no R directory", {
  skip_on_cran()
  
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

  if (package_installed == TRUE ) {
    
    # setup parameters for running covr
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)
    
    covr_timeout <- Inf
    
    covr_list <- suppressMessages(run_coverage(
      pkg_source_path,  # must use untarred package dir
      covr_timeout)
    )
    
    testthat::expect_message(
      tm_list <- create_traceability_matrix(pkg_name, 
                                       pkg_source_path, 
                                       covr_list$res_cov),
      glue::glue("creating traceability matrix for {basename(pkg_source_path)}"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      tm_list <- create_traceability_matrix(pkg_name, 
                                       pkg_source_path, 
                                       covr_list$res_cov),
      glue::glue("traceability matrix for {basename(pkg_source_path)} unsuccessful"),
      fixed = TRUE
    )
    
    testthat::expect_message(
      tm_list <- create_traceability_matrix(pkg_name, 
                                       pkg_source_path, 
                                       covr_list$res_cov),
      glue::glue("no R folder to create traceability matrix for {basename(pkg_source_path)}"),
      fixed = TRUE
    )
    
  } else {
    message(glue::glue("cannot run traceability matrix for {basename(pkg_source_path)}"))
  } 
  
})

test_that("running tm for created package in tar file with empty R directory", {
  skip_on_cran()
  
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

  if (package_installed == TRUE ) {

    # setup parameters for running covr
    pkg_desc <- get_pkg_desc(pkg_source_path, fields = c("Package", "Version"))
    pkg_name <- pkg_desc$Package
    pkg_ver <- pkg_desc$Version
    pkg_name_ver <- paste0(pkg_name, "_", pkg_ver)

    covr_timeout <- Inf

    covr_list <- suppressMessages(run_coverage(
      pkg_source_path,  # must use untarred package dir
      covr_timeout)
    )

    testthat::expect_message(
      {
        tm <- try(
          create_traceability_matrix(pkg_name, pkg_source_path, covr_list$res_cov),
          silent = TRUE
        )
      },
      "creating traceability matrix for test.package.0005",
      fixed = TRUE
    )
    
    testthat::expect_message(
      {
        tm <- try(
          create_traceability_matrix(pkg_name, pkg_source_path, covr_list$res_cov),
          silent = TRUE
        )
      },
      "No top level assignments found in R folder for test.package.0005",
      fixed = TRUE
    )
    } else {
    message(glue::glue("cannot run traceability matrix for {basename(pkg_source_path)}"))
  }

})

test_that("get_toplevel_assignments works correctly", {
  # Mock the tools::list_files_with_type function
  mock_list_files_with_type <- function(path, type) {
    if (path == "dummy_path/R") {
      return(c("file1.R", "file2.R"))
    }
    return(character(0))
  }
  
  # Mock the parse function
  mock_parse <- function(file) {
    if (file == "file1.R") {
      return(parse(text = "func1 <- function() {}"))
    } else if (file == "file2.R") {
      return(parse(text = "func2 <- function() {}"))
    }
    stop("Unexpected file")
  }
  
  # Mock the fs::path_rel function
  mock_path_rel <- function(path, start) {
    return(basename(path))
  }
  
  pkg_name <- "dummy_path"
  
  # Use mockery to stub the functions
  mockery::stub(get_toplevel_assignments, "tools::list_files_with_type", mock_list_files_with_type)
  mockery::stub(get_toplevel_assignments, "parse", mock_parse)
  mockery::stub(get_toplevel_assignments, "fs::path_rel", mock_path_rel)
  
  # Test case: Normal scenario
  result <- get_toplevel_assignments(pkg_name)
  expect_equal(result$func, c("func1", "func2"))
  expect_equal(result$code_script, c("file1.R", "file2.R"))
  
  # Test case: No R files found
  mock_list_files_with_type_empty <- function(path, type) {
    return(character(0))
  }
  
  mockery::stub(get_toplevel_assignments, "tools::list_files_with_type", mock_list_files_with_type_empty)
  
  messages <- capture_messages(result <- get_toplevel_assignments(pkg_name))
  print(messages)
  expect_true(any(grepl(glue::glue("No sourceable R scripts were found in the R/ directory for package {pkg_name}. Make sure this was expected."), messages)))
  expect_equal(nrow(result), 0)
})

test_that("map_functions_to_scripts returns correct mapping", {
  # Mock the exports_df
  exports_df <- dplyr::tibble(exported_function = c("function1", "function2", "generic1"),
                              class = c(NA, NA, "class1"))
  
  # Mock the funcs_df
  funcs_df <- dplyr::tibble(func = c("function1", "function2", "generic1.class1"), code_script = c("script1.R", "script2.R", "script3.R"))
  
  # Mock the get_toplevel_assignments function
  mock_get_toplevel_assignments <- mockery::mock(funcs_df)
  mockery::stub(map_functions_to_scripts, "get_toplevel_assignments", mock_get_toplevel_assignments)
  
  # Call the function
  result <- map_functions_to_scripts(exports_df, "mock/path", verbose = FALSE)
  
  # Expected result
  expected <- dplyr::tibble(
    exported_function = c("function1", "function2", "generic1"),
    class = c(NA, NA, "class1"),
    join_key = c("function1", "function2", "generic1.class1"),
    code_script = c("script1.R", "script2.R", "script3.R")
  )
  
  # Check the result
  expect_equal(result, expected)
})

test_that("map_functions_to_scripts handles no top level assignments found", {
  # Mock the exports_df
  exports_df <- dplyr::tibble(exported_function = c("function1", "function2", "generic1"),
                              class = c(NA, NA, "class1"))
  
  # Mock the funcs_df with no assignments
  funcs_df <- dplyr::tibble()
  
  # Mock the get_toplevel_assignments function
  mock_get_toplevel_assignments <- mockery::mock(funcs_df)
  mockery::stub(map_functions_to_scripts, "get_toplevel_assignments", mock_get_toplevel_assignments)
  
  # Call the function
  result <- map_functions_to_scripts(exports_df, "mock/path", verbose = FALSE)
  
  # Expected result
  expected <- data.frame()
  
  # Check the result
  expect_equal(result, expected)
})

test_that("map_functions_to_scripts handles missing functions in scripts", {
  # Mock the exports_df
  exports_df <- dplyr::tibble(exported_function = c("function1", "function2", "generic1"),
                              class = c(NA, NA, "class1"))
  
  # Mock the funcs_df with missing functions
  funcs_df <- dplyr::tibble(func = c("function1"), code_script = c("script1.R"))
  
  # Mock the get_toplevel_assignments function
  mock_get_toplevel_assignments <- mockery::mock(funcs_df)
  mockery::stub(map_functions_to_scripts, "get_toplevel_assignments", mock_get_toplevel_assignments)
  
  # Call the function
  result <- map_functions_to_scripts(exports_df, "mock/path", verbose = TRUE)
  
  # Expected result
  expected <- dplyr::tibble(
    exported_function = c("function1", "function2", "generic1"),
    class = c(NA, NA, "class1"),
    join_key = c("function1", "function2", "generic1.class1"),
    code_script = c("script1.R", NA, NA)
  )
  
  # Check the result
  expect_equal(result, expected)
})

test_that("map_functions_to_docs returns correct mapping", {
  # Mock the exports_df
  exports_df <- dplyr::tibble(exported_function = c("function1", "function2", "generic1"),
                              class = c(NA, NA, "class1"),
                              join_key = c("function1", "function2", "generic1.class1"))
  
  # Mock the Rd files
  rd_files <- c("man/function1.Rd", "man/function2.Rd", "man/generic1.class1.Rd")
  
  # Mock the list.files function
  mock_list_files <- mockery::mock(rd_files)
  mockery::stub(map_functions_to_docs, "list.files", mock_list_files)
  
  # Mock the readLines function
  mock_read_lines <- mockery::mock(
    c("\\name{function1}", "\\alias{function1}"),
    c("\\name{function2}", "\\alias{function2}"),
    c("\\name{generic1.class1}", "\\alias{generic1.class1}")
  )
  mockery::stub(map_functions_to_docs, "readLines", mock_read_lines)
  
  # Call the function
  result <- map_functions_to_docs(exports_df, "mock/path", verbose = FALSE)
  
  # Expected result
  expected <- dplyr::tibble(
    exported_function = c("function1", "function2", "generic1"),
    class = c(NA, NA, "class1"),
    documentation = c("function1.Rd", "function2.Rd", "generic1.class1.Rd")
  )
  
  # Check the result
  expect_equal(result, expected)
})

test_that("map_functions_to_docs handles no documentation found", {
  # Mock the exports_df
  exports_df <- dplyr::tibble(exported_function = c("function1", "function2", "generic1"),
                              class = c(NA, NA, "class1"),
                              join_key = c("function1", "function2", "generic1.class1"))
  
  # Mock the Rd files with no documentation
  rd_files <- character(0)
  
  # Mock the list.files function
  mock_list_files <- mockery::mock(rd_files)
  mockery::stub(map_functions_to_docs, "list.files", mock_list_files)
  
  # Call the function
  result <- map_functions_to_docs(exports_df, "mock/path", verbose = FALSE)
  
  # Expected result
  expected <- dplyr::mutate(exports_df, documentation = NA)
  
  # Check the result
  expect_equal(result, expected)
})

test_that("map_functions_to_docs handles missing functions in documentation", {
  # Mock the exports_df
  exports_df <- dplyr::tibble(exported_function = c("function1", "function2", "generic1"),
                              class = c(NA, NA, "class1"),
                              join_key = c("function1", "function2", "generic1.class1"))
  
  # Mock the Rd files with missing functions
  rd_files <- c("man/function1.Rd")
  
  # Mock the list.files function
  mock_list_files <- mockery::mock(rd_files)
  mockery::stub(map_functions_to_docs, "list.files", mock_list_files)
  
  # Mock the readLines function
  mock_read_lines <- mockery::mock(c("\\name{function1}", "\\alias{function1}"))
  mockery::stub(map_functions_to_docs, "readLines", mock_read_lines)
  
  # Call the function
  result <- map_functions_to_docs(exports_df, "mock/path", verbose = TRUE)
  
  # Expected result
  expected <- dplyr::tibble(
    exported_function = c("function1", "function2", "generic1"),
    class = c(NA, NA, "class1"),
    documentation = c("function1.Rd", NA, NA)
  )
  
  # Check the result
  expect_equal(result, expected)
})

test_that("filter_symbol_functions filters out symbols correctly", {
  # Mocked data
  funcs <- c("%>%", "$", "[[", "[", "+", "%", "<-", "function1", "function2")
  
  # Call the function
  result <- filter_symbol_functions(funcs)
  
  # Expected result
  expected <- c("function1", "function2")
  
  # Check the result
  expect_equal(result, expected)
})

test_that("filter_symbol_functions handles empty input", {
  # Mocked data
  funcs <- character(0)
  
  # Call the function
  result <- filter_symbol_functions(funcs)
  
  # Expected result
  expected <- character(0)
  
  # Check the result
  expect_equal(result, expected)
})

test_that("filter_symbol_functions handles input with no symbols", {
  # Mocked data
  funcs <- c("function1", "function2", "function3")
  
  # Call the function
  result <- filter_symbol_functions(funcs)
  
  # Expected result
  expected <- c("function1", "function2", "function3")
  
  # Check the result
  expect_equal(result, expected)
})

test_that("filter_symbol_functions handles input with only symbols", {
  # Mocked data
  funcs <- c("%>%", "$", "[[", "[", "+", "%", "<-")
  
  # Call the function
  result <- filter_symbol_functions(funcs)
  
  # Expected result
  expected <- character(0)
  
  # Check the result
  expect_equal(result, expected)
})

test_that("fine_grained_tms correctly categorizes coverage levels", {
  tm <- data.frame(
    function_name = c("f1", "f2", "f3"),
    coverage_percent = c(50, 70, 90),
    function_body = c("", "", ""),
    code_script = c("", "", ""),
    description = c("", "", ""),
    documentation = c("", "", ""),
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$coverage$high_risk), 1)
  expect_equal(nrow(result$coverage$medium_risk), 1)
  expect_equal(nrow(result$coverage$low_risk), 1)
})

test_that("fine_grained_tms handles defunct functions", {
  tm <- data.frame(
    function_name = "f_defunct",
    coverage_percent = 100,
    function_body = "This function is defunct",
    code_script = "",
    description = "",
    documentation = "",
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$function_type$defunct), 1)
})

test_that("fine_grained_tms handles imported functions", {
  tm <- data.frame(
    function_name = "f_imported",
    coverage_percent = 100,
    function_body = "",
    code_script = "This function is imported",
    description = "",
    documentation = "",
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$function_type$imported), 1)
})

test_that("fine_grained_tms handles reexported functions", {
  tm <- data.frame(
    function_name = "f_reexported",
    coverage_percent = 100,
    function_body = "",
    code_script = "This function is re-exported",
    description = "",
    documentation = "",
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$function_type$rexported), 1)
})

test_that("fine_grained_tms handles experimental functions", {
  tm <- data.frame(
    function_name = "f_experimental",
    coverage_percent = 100,
    function_body = "",
    code_script = "This function is experimental",
    description = "",
    documentation = "",
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$function_type$experimental), 1)
})


test_that("fine_grained_tms correctly categorizes coverage levels", {
  tm <- data.frame(
    function_name = c("f1", "f2", "f3"),
    coverage_percent = c(50, 70, 90),
    function_body = c("", "", ""),
    code_script = c("", "", ""),
    description = c("", "", ""),
    documentation = c("", "", ""),
    stringsAsFactors = FALSE
  )
  
  result <- fine_grained_tms(tm, "testpkg")
  
  expect_equal(nrow(result$coverage$high_risk), 1)
  expect_equal(nrow(result$coverage$medium_risk), 1)
  expect_equal(nrow(result$coverage$low_risk), 1)
})


test_that("create_traceability_matrix works without coverage", {
  pkg_name <- "mockpkg"
  pkg_source_path <- "mock/path"
  func_covr <- NULL  # not used when execute_coverage = FALSE
  
  # Mocked data for exports_df
  mock_exports_df <- data.frame(
    exported_function = c("func1", "func2"),
    class = c("S3", "S4"),
    code_script = c("script1.R", "script2.R"),
    stringsAsFactors = FALSE
  )
  
  # Stub all dependencies
  mockery::stub(create_traceability_matrix, "contains_r_folder", TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", mock_exports_df)
  mockery::stub(create_traceability_matrix, "map_functions_to_scripts", mock_exports_df)
  mockery::stub(create_traceability_matrix, "map_functions_to_docs", mock_exports_df)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", list(func1 = "desc1", func2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg_name) {
    list(total_tm = tm)
  })
  
  # Run the function with execute_coverage = FALSE
  result <- create_traceability_matrix(pkg_name, pkg_source_path, func_covr, execute_coverage = FALSE)
  
  # Assertions
  expect_type(result, "list")
  expect_true("total_tm" %in% names(result))
  expect_equal(nrow(result$total_tm), 2)
  expect_equal(result$total_tm$coverage_percent, c(0, 0))  # joined with dummy coverage
})

test_that("create_traceability_matrix creates dummy func_covr when input is NULL", {
  pkg_name <- "mockPkg"
  pkg_source_path <- "mock/path"
  
  # Mocked exports_df
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c("S3", "S4"),
    code_script = c("R/fun1.R", "R/fun2.R"),
    stringsAsFactors = FALSE
  )
  
  # Stub all dependencies
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "map_functions_to_scripts", function(df, path, verbose) df)
  mockery::stub(create_traceability_matrix, "map_functions_to_docs", function(df, path, verbose) df)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  # Run the function with func_covr = NULL
  result <- create_traceability_matrix(pkg_name, pkg_source_path, func_covr = NULL, execute_coverage = TRUE)
  
  # Assertions
  expect_type(result, "list")
  expect_true("tm" %in% names(result))
  expect_equal(result$tm$coverage_percent, c(0, 0))
  expect_equal(result$tm$code_script, (c("R/fun1.R", "R/fun2.R")))
})

test_that("create_traceability_matrix creates dummy func_covr when coverage is missing", {
  pkg_name <- "mockPkg"
  pkg_source_path <- "mock/path"
  
  mock_exports_df <- data.frame(
    exported_function = c("fun1", "fun2"),
    class = c("S3", "S4"),
    code_script = c("R/fun1.R", "R/fun2.R"),
    stringsAsFactors = FALSE
  )
  
  bad_func_covr <- list(
    name = pkg_name,
    coverage = NULL,
    errors = NA,
    notes = NA
  )
  
  mockery::stub(create_traceability_matrix, "contains_r_folder", function(path) TRUE)
  mockery::stub(create_traceability_matrix, "get_exports", function(path) mock_exports_df)
  mockery::stub(create_traceability_matrix, "map_functions_to_scripts", function(df, path, verbose) df)
  mockery::stub(create_traceability_matrix, "map_functions_to_docs", function(df, path, verbose) df)
  mockery::stub(create_traceability_matrix, "get_func_descriptions", function(pkg) list(fun1 = "desc1", fun2 = "desc2"))
  mockery::stub(create_traceability_matrix, "fine_grained_tms", function(tm, pkg) list(tm = tm))
  
  result <- create_traceability_matrix(pkg_name, pkg_source_path, func_covr = bad_func_covr, execute_coverage = TRUE)
  
  expect_type(result, "list")
  expect_true("tm" %in% names(result))
  expect_equal(result$tm$coverage_percent, c(0, 0))
})


