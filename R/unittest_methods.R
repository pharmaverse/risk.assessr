#' Check for tests/testthat and _snaps folder and count golden tests
#'
#' @param pkg_source_path Path to the root of the package source
#'
#' @return A list with:
#'   - `has_testthat`: Does tests/testthat exist?
#'   - `has_testit`: Does tests/testit exist?
#'   - `has_snaps`: Does _snaps exist inside tests/testthat?
#'   - `n_golden_tests`: Number of snapshot files inside _snaps
#'   - `n_test_files`: Number of test-*.R files inside tests/testthat
#' @keywords internal
check_pkg_tests_and_snaps <- function(pkg_source_path) {
  message("checking package test config")
 
  testthat_path <- file.path(pkg_source_path, "tests", "testthat")
  snaps_path <- file.path(testthat_path, "_snaps")
  
  testit_path <- file.path(pkg_source_path, "tests", "testit")
  test_ci_path <- file.path(pkg_source_path, "tests", "test-ci")
  test_cran_path <- file.path(pkg_source_path, "tests", "test-cran")
  
  # Check testit standard config first
  if (dir.exists(testit_path)) {
    has_testit <- TRUE
  } else {
    # check for nonstandard testit config
    has_testit <- dir.exists(test_ci_path) && dir.exists(test_cran_path)
  }
  
  has_testthat <- dir.exists(testthat_path)
  has_snaps <- dir.exists(snaps_path)
  
  # Count golden test snapshot files
  n_golden_tests <- if (has_snaps) {
    snapshot_files <- list.files(snaps_path, recursive = TRUE, full.names = TRUE)
    length(snapshot_files)
  } else {
    0
  }
  
  # Count test-*.R files 
  n_test_files <- if (has_testthat) {
    test_files <- list.files(
      testthat_path,
      pattern = "^test-.*\\.R$",
      recursive = TRUE,
      full.names = TRUE
    )
    test_files <- test_files[!grepl("_snaps", test_files)]
    length(test_files)
  } else {
    0
  }
  
  return(list(
    has_testthat = has_testthat,
    has_snaps = has_snaps,
    has_testit = has_testit,
    n_golden_tests = n_golden_tests,
    n_test_files = n_test_files
  ))
}



