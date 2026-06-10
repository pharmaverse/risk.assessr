test_that("check_suggested_exp_funcs returns 2 matches", {
  skip_on_cran()
  r = getOption("repos")
  r["CRAN"] = "http://cran.us.r-project.org"
  options(repos = r)
  skip_if_repo_unavailable()
  
  dp <- system.file("test-data", "here-1.0.1.tar.gz",
                    package = "risk.assessr")
  skip_if_test_data_missing(dp)
  
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
  skip_if_test_data_missing(dp_orig)
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
  skip_if_test_data_missing(dp_orig)
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
  skip_if_test_data_missing(dp_orig)
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
  skip_if_repo_unavailable()
  
  # Copy test package to a temp file
  dp_orig <- system.file("test-data", 
                         "test.package.0011_0.1.0.tar.gz", 
                         package = "risk.assessr")
  skip_if_test_data_missing(dp_orig)
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
  skip_if_test_data_missing(dp_orig)
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
  skip_if_test_data_missing(dp_orig)
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

test_that("process_items_matched does not match plain names as substrings", {
  # Regression guard for the boundary change (\b -> (?<!\w)...(?!\w)).
  # 'n' must NOT match the embedded 'n' inside 'meaningful_n_count'.
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "meaningful_n_count <- mean(x)"
  )
  local_funcs <- dplyr::tibble(
    package = c("dplyr", "base"),
    functions = c("n", "mean")
  )
  
  result <- process_items_matched(local_items, local_funcs)
  
  expect_equal(nrow(result), 1L)
  expect_equal(result$suggested_function, "mean")
  expect_equal(result$targeted_package, "base")
})

test_that("process_items_matched extracts '%in%' end-to-end", {
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "x %in% y"
  )
  local_funcs <- dplyr::tibble(
    package = "base",
    functions = "%in%"
  )
  
  expect_no_warning(
    result <- process_items_matched(local_items, local_funcs)
  )
  
  expect_equal(nrow(result), 1L)
  expect_equal(result$suggested_function, "%in%")
  expect_equal(result$targeted_package, "base")
})

test_that("process_items_matched extracts '[<-.integer64' end-to-end", {
  # The unquoted construction in the previous heuristics raised
  #   invalid regular expression '\\b[data\\b\\s*(<-|=)'
  # for names starting with '['. The Option B refactor should handle these.
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "uses [<-.integer64 somewhere in the body"
  )
  local_funcs <- dplyr::tibble(
    package = "bit64",
    functions = "[<-.integer64"
  )
  
  expect_no_warning(
    result <- process_items_matched(local_items, local_funcs)
  )
  
  expect_equal(nrow(result), 1L)
  expect_equal(result$suggested_function, "[<-.integer64")
  expect_equal(result$targeted_package, "bit64")
})

test_that("process_items_matched extracts '+.Date' end-to-end", {
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "uses +.Date somewhere in the body"
  )
  local_funcs <- dplyr::tibble(
    package = "base",
    functions = "+.Date"
  )
  
  expect_no_warning(
    result <- process_items_matched(local_items, local_funcs)
  )
  
  expect_equal(nrow(result), 1L)
  expect_equal(result$suggested_function, "+.Date")
  expect_equal(result$targeted_package, "base")
})

test_that("process_items_matched prefers longer matches (mean_se over mean)", {
  # ICU alternation tries alternatives left-to-right at each position; sorting
  # by nchar desc protects against shorter prefixes shadowing longer names if
  # the lookaround boundary were ever relaxed.
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "mean_se(x)"
  )
  local_funcs <- dplyr::tibble(
    package = c("base", "ggplot2"),
    functions = c("mean", "mean_se")
  )
  
  result <- process_items_matched(local_items, local_funcs)
  
  expect_equal(nrow(result), 1L)
  expect_equal(result$suggested_function, "mean_se")
  expect_equal(result$targeted_package, "ggplot2")
})

test_that("process_items_matched ignores NA and empty function names", {
  # Body deliberately contains the literal token 'NA' to catch the prior bug
  # where an NA in suggested_exp_func$functions became an "NA" alternative in
  # the regex.
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "y <- NA; z <- mutate(x)"
  )
  local_funcs <- dplyr::tibble(
    package = c("dplyr", "ghost1", "ghost2"),
    functions = c("mutate", NA, "")
  )
  
  expect_no_warning(
    result <- process_items_matched(local_items, local_funcs)
  )
  
  expect_equal(nrow(result), 1L)
  expect_equal(result$suggested_function, "mutate")
  expect_equal(result$targeted_package, "dplyr")
})

test_that("process_items_matched returns empty result when no valid names remain", {
  # All entries filtered out -> empty schema, no degenerate regex.
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "anything goes here"
  )
  local_funcs <- dplyr::tibble(
    package = c("ghost1", "ghost2"),
    functions = c(NA, "")
  )
  
  result <- process_items_matched(local_items, local_funcs)
  
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
  expect_named(
    result,
    c("source", "suggested_function", "targeted_package", "message")
  )
})

test_that("process_items_matched still filters out assignment targets (plain names)", {
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "mutate <- function() 1"
  )
  local_funcs <- dplyr::tibble(
    package = "dplyr",
    functions = "mutate"
  )
  
  result <- process_items_matched(local_items, local_funcs)
  
  expect_equal(nrow(result), 0L)
})

test_that("process_items_matched still filters out positional parameter uses", {
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "foo(x, mutate)"
  )
  local_funcs <- dplyr::tibble(
    package = "dplyr",
    functions = "mutate"
  )
  
  result <- process_items_matched(local_items, local_funcs)
  
  expect_equal(nrow(result), 0L)
})

test_that("process_items_matched heuristics do not crash on special-character names", {
  # Smoke test: every code path that builds an anchored() regex must survive
  # a name like '[<-.integer64' (used to raise 'invalid regular expression').
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "wrapper(a, [<-.integer64, b)"
  )
  local_funcs <- dplyr::tibble(
    package = "bit64",
    functions = "[<-.integer64"
  )
  
  expect_no_error(
    result <- process_items_matched(local_items, local_funcs)
  )
  # The name appears as a positional argument inside foo(...), so the
  # is_parameter heuristic correctly drops it -- the important point of this
  # test is that the heuristic ran without an "invalid regular expression"
  # error, not the row count.
  expect_s3_class(result, "tbl_df")
})

# ---------------------------------------------------------------------------
# Extension of the existing assignment / parameter / mapping coverage to
# special-character names + a dedicated test for the regex-failure fallback
# path (the tryCatch error arm on lines 88-104 of check_suggested_exp_funcs.R,
# which was previously uncovered).
# ---------------------------------------------------------------------------

test_that("process_items_matched filters out assignment to '%in%'", {
  # is_assignment regex is built via anchored("%in%") + "\\s*(<-|=)". With the
  # old "\\b" + name + "\\b" construction this crashed for names whose first or
  # last character is non-word; the Option B refactor uses (?<!\\w)\\Q...\\E(?!\\w)
  # so '%in%' is detected as an assignment target and correctly filtered.
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "%in% <- function(x, y) FALSE"
  )
  local_funcs <- dplyr::tibble(
    package = "base",
    functions = "%in%"
  )
  
  expect_no_warning(
    result <- process_items_matched(local_items, local_funcs)
  )
  expect_equal(nrow(result), 0L)
})

test_that("process_items_matched filters out '+.Date' used as a positional argument", {
  # '+.Date' sits between '(' and ')' (in_parens = TRUE), is not followed by
  # '<-' or '=' (is_assign = FALSE), and is not followed by '(' (is_call_lhs
  # = FALSE) -> is_parameter = TRUE -> row dropped. Confirms the parameter
  # heuristic is exercised — and survives — for non-word-character names.
  local_items <- dplyr::tibble(
    source = "file1",
    suggested_function = "do.call(fn, list(+.Date, x))"
  )
  local_funcs <- dplyr::tibble(
    package = "base",
    functions = "+.Date"
  )
  
  expect_no_warning(
    result <- process_items_matched(local_items, local_funcs)
  )
  expect_equal(nrow(result), 0L)
})

test_that("process_items_matched maps targeted_package correctly across mixed special + plain names", {
  # Two rows: one body uses '%in%' (special-character name, base), the other
  # uses 'mutate' (plain name, dplyr). Verifies that:
  #   * alt_pattern matches BOTH name shapes in a single regex pass
  #   * neither is dropped by the is_assignment / is_parameter heuristics in
  #     these realistic call positions
  #   * the per-row match() lookup against suggested_exp_func$functions returns
  #     the correct targeted_package for each row independently
  # This is the end-to-end mapping test the user explicitly requested.
  local_items <- dplyr::tibble(
    source = c("file1", "file2"),
    suggested_function = c(
      "a %in% b",                       # special-character call
      "result <- dplyr::mutate(x, y)"   # plain-name call (RHS, not assignment target)
    )
  )
  local_funcs <- dplyr::tibble(
    package   = c("base", "dplyr"),
    functions = c("%in%", "mutate")
  )
  
  result <- process_items_matched(local_items, local_funcs)
  result <- result[order(result$source), ]
  
  expect_equal(nrow(result), 2L)
  expect_equal(result$suggested_function, c("%in%",  "mutate"))
  expect_equal(result$targeted_package,   c("base",  "dplyr"))
  expect_true(all(result$message ==
                    "Please check if the targeted package should be in Imports"))
})

test_that("process_items_matched falls back to fixed-string matching when ICU regex extraction errors", {
  # Covers the tryCatch error arm on lines 88-104 of check_suggested_exp_funcs.R.
  # The fallback:
  #   1. emits a warning describing the failure
  #   2. iterates over all_functions and uses stringr::str_detect(body, fixed(fn))
  #      to find which names appear as literals in the body
  #   3. returns the matched names so the rest of the pipeline (is_assignment /
  #      is_parameter / targeted_package mapping) runs unchanged
  #
  # We trigger the error by mocking ONLY stringr::str_extract_all to throw.
  # local_mocked_bindings is used (rather than mockery::stub) because the call
  # site is inside the nested extract_calls() closure, and namespace-level
  # binding replacement guarantees the mock is picked up regardless of where
  # in the call graph the function is invoked. str_detect and fixed remain
  # unmocked so the fallback's literal-matching path executes for real.
  local_items <- dplyr::tibble(
    source             = c("file1",            "file2"),
    suggested_function = c("uses mutate here", "calls str_detect(x, 'a')")
  )
  local_funcs <- dplyr::tibble(
    package   = c("dplyr",  "stringr"),
    functions = c("mutate", "str_detect")
  )
  
  testthat::local_mocked_bindings(
    str_extract_all = function(...) stop("forced ICU failure"),
    .package = "stringr"
  )
  
  # Defensive assignment pattern: write to `result` INSIDE the expression so the
  # binding always happens regardless of what expect_warning() returns.
  # `result <- expect_warning(...)` is fragile because some testthat versions
  # do not invisibly return the captured value, leaving `result` as NULL and
  # producing the misleading "argument 1 is not a vector" error from order().
  result <- NULL
  expect_warning(
    result <- process_items_matched(local_items, local_funcs),
    "regex extraction failed.*fixed-string matching"
  )
  
  # Guard rail: if the inner expression somehow errored or the fallback failed
  # to return a tibble, fail loudly here instead of letting the misleading
  # order() error mask the real cause.
  expect_true(is.data.frame(result))
  expect_named(result,
               c("source", "suggested_function", "targeted_package", "message"))
  
  result <- result[order(result$source), ]
  expect_equal(nrow(result), 2L)
  expect_equal(result$suggested_function, c("mutate", "str_detect"))
  expect_equal(result$targeted_package,   c("dplyr",  "stringr"))
  expect_true(all(result$message ==
                    "Please check if the targeted package should be in Imports"))
})

test_that("process_items_matched fallback preserves word-boundary semantics (no substring false positives)", {
  # Regression test for the Option B fix: the ICU-failure fallback must NOT
  # match `mean` inside `meaningful`, `n` inside `function`, etc. — i.e. it
  # must reproduce the (?<!\\w)...(?!\\w) boundary semantics of the main
  # alt_pattern, otherwise the two code paths produce inconsistent results.
  #
  # The naive `stringr::str_detect(body, stringr::fixed(fn))` previously used
  # in the fallback would match all three names below; the downstream
  # is_assignment / is_parameter heuristics do NOT compensate, so the
  # false positives ('mean' and 'n') would surface in the output.
  #
  # We force the fallback via the same local_mocked_bindings trick as the
  # fallback test above; str_locate_all and fixed remain real so the
  # boundary-preserving logic executes end-to-end.
  local_items <- dplyr::tibble(
    source             = "file1",
    suggested_function = "meaningful_count <- mean(x); function() x"
  )
  local_funcs <- dplyr::tibble(
    package   = c("base", "dplyr", "base"),
    functions = c("mean", "n",     "function")  # 'function' is a substring of "function()" but flanked by '('
  )
  
  testthat::local_mocked_bindings(
    str_extract_all = function(...) stop("forced ICU failure"),
    .package = "stringr"
  )
  
  result <- NULL
  expect_warning(
    result <- process_items_matched(local_items, local_funcs),
    "regex extraction failed.*fixed-string matching"
  )
  
  expect_true(is.data.frame(result))
  expect_named(result,
               c("source", "suggested_function", "targeted_package", "message"))
  
  # 'mean' MUST appear: it occurs at position 21 of the body as a real call,
  # flanked by ' ' before and '(' after — both non-word, so the boundary check
  # accepts this occurrence (NOT the one inside "meaningful").
  expect_true("mean" %in% result$suggested_function)
  
  # 'n' MUST NOT appear: every literal occurrence in the body is inside a
  # word ('meaningful_count', 'function'), so the boundary check rejects all
  # of them. The naive fixed-string fallback would have included it.
  expect_false("n" %in% result$suggested_function)
  
  # 'function' MUST appear: the literal "function" in "function()" is flanked
  # by ' ' before (after the ';') and '(' after — both non-word — so the
  # boundary check accepts it. This documents that the fallback correctly
  # distinguishes legitimate non-word-bounded calls from sub-identifier hits.
  expect_true("function" %in% result$suggested_function)
  
  # targeted_package mapping must still be correct on the surviving rows.
  retained <- result[order(result$suggested_function), ]
  expect_equal(retained$suggested_function, c("function", "mean"))
  expect_equal(retained$targeted_package,   c("base",     "base"))
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


test_that("check_suggested_exp_funcs handles empty exported functions from source package", {
  # Mock inputs
  pkg_name <- "mockpkg"
  pkg_source_path <- "mock/path"
  suggested_deps <- data.frame(package = "dplyr", stringsAsFactors = FALSE)
  
  # Stub functions to simulate conditions
  mockery::stub(check_suggested_exp_funcs, "contains_r_folder", function(...) TRUE)
  
  # Simulate get_exports returning a data frame with only NA or blank values
  mockery::stub(check_suggested_exp_funcs, "get_exports", function(...) {
    data.frame(exported_function = c(NA, " "), function_body = c(NA, " "), stringsAsFactors = FALSE)
  })
  
  # Simulate get_suggested_exp_funcs returning a valid data frame
  mockery::stub(check_suggested_exp_funcs, "get_suggested_exp_funcs", function(...) {
    data.frame(suggested_function = c("filter"), targeted_package = c("dplyr"), stringsAsFactors = FALSE)
  })
  
  # Run the function
  result <- check_suggested_exp_funcs(pkg_name, pkg_source_path, suggested_deps)
  
  # Check the result
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 1)
  expect_equal(result$source, pkg_name)
  expect_true(is.na(result$suggested_function))
  expect_true(is.na(result$targeted_package))
  expect_match(result$message, "No exported functions from source package")
})
