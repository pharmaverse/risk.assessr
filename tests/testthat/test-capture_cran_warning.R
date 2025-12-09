test_that("capture_cran_warning handles timeout warning", {
  # Stub url() to trigger a warning
  mockery::stub(capture_cran_warning, "url", function(...) {
    warning("URL 'http://lib.stat.cmu.edu/R/CRAN/src/contrib/Meta/archive.rds': Timeout of 60 seconds was reached")
    return(NULL)
  })
  
  result <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  expect_equal(result$status, "warning")
  expect_match(result$message, "Timeout of 60 seconds was reached")
})


test_that("capture_cran_warning handles URL error", {
  # Stub url() to trigger an error
  mockery::stub(capture_cran_warning, "url", function(...) {
    stop("cannot open URL 'http://lib.stat.cmu.edu/R/CRAN/src/contrib/Meta/archive.rds'")
  })
  
  result <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  expect_equal(result$status, "url_error")
  expect_match(result$message, "cannot open URL")
})


test_that("capture_cran_warning returns timeout status for 504 Gateway Timeout", {
  mockery::stub(capture_cran_warning, "url", function(...) {
    stop("HTTP status was '504 Gateway Timeout'")
  })
  
  result <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  expect_equal(result$status, "timeout")
  expect_match(result$message, "504 Gateway Timeout")
})

test_that("capture_cran_warning handles successful connection", {
  # Stub url() and readBin() to simulate success
  mockery::stub(capture_cran_warning, "url", function(...) rawConnection(raw(0)))
  mockery::stub(capture_cran_warning, "readBin", function(...) raw(0))
  
  result <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  expect_equal(result$status, "success")
  expect_null(result$message)
})


test_that("capture_cran_warning returns generic error status for unknown error", {
  mockery::stub(capture_cran_warning, "url", function(...) {
    stop("Some unexpected error occurred")
  })
  
  result <- capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
  
  expect_equal(result$status, "error")
  expect_match(result$message, "unexpected error")
})

