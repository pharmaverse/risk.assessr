test_that("run_rcmdcheck returns score of 1 when no issues found", {
  pkg_path <- "path/to/test.pkg"
  args <- list(quiet = TRUE)
  
  # Mock rcmdcheck to return empty results
  mock_res <- list(notes = character(0), warnings = character(0), errors = character(0))
  mockery::stub(run_rcmdcheck, "rcmdcheck::rcmdcheck", mock_res)
  
  # Mock forbidden notes to return input as-is
  mockery::stub(run_rcmdcheck, "check_forbidden_notes", function(x, y) x)
  
  testthat::expect_message(
    res <- run_rcmdcheck(pkg_path, args),
    "rcmdcheck for test.pkg passed"
  )
  
  testthat::expect_equal(res$check_score, 1)
  testthat::expect_identical(res$res_check, mock_res)
})

test_that("run_rcmdcheck handles errors and calculates score of 0", {
  pkg_path <- "path/to/test.pkg"
  
  # Mock rcmdcheck to return one error
  mock_res <- list(notes = character(0), warnings = character(0), errors = "One critical error")
  mockery::stub(run_rcmdcheck, "rcmdcheck::rcmdcheck", mock_res)
  mockery::stub(run_rcmdcheck, "check_forbidden_notes", function(x, y) x)
  
  testthat::expect_message(
    res <- run_rcmdcheck(pkg_path, list()),
    "rcmdcheck for test.pkg failed"
  )
  
  # Error weighting is 1.0, so 1 - 1.0 = 0
  testthat::expect_equal(res$check_score, 0)
})

test_that("run_rcmdcheck accounts for forbidden notes escalated to errors", {
  pkg_path <- "path/to/test.pkg"
  
  # Initial check returns 1 note
  mock_res <- list(notes = "no visible global function definition", warnings = character(0), errors = character(0))
  mockery::stub(run_rcmdcheck, "rcmdcheck::rcmdcheck", mock_res)
  
  # The real check_forbidden_notes should move that note to errors
  # (No stub for check_forbidden_notes here so we test the integration)
  
  res <- run_rcmdcheck(pkg_path, list())
  
  # Note becomes error (weight 1.0), so score should be 0, not 0.9
  testthat::expect_equal(res$check_score, 0)
  testthat::expect_length(res$res_check$errors, 1)
})



