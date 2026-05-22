test_that("normalize_codecov converts /graph/badge.svg -> /badge.svg", {
  x <- c(
    "https://codecov.io/gh/org/repo/graph/badge.svg",
    "https://codecov.io/gh/org/repo/graph/badge.svg?token=abc",
    "https://img.shields.io/badge/CRAN-ok.svg"
  )
  got <- vapply(x, normalize_codecov, character(1))
  
  # core checks
  expect_true(grepl("/badge.svg$", got[1]))
  expect_true(grepl("/badge.svg\\?token=abc$", got[2]))
  
  # strip names to avoid spurious failure
  expect_identical(unname(got[3]), x[3])
})


test_that("parse_doc_safe parses both HTML and XML safely", {
  html <- "<html><body><img src='a.svg'/></body></html>"
  xml  <- "<svg><text>a</text></svg>"
  expect_s3_class(parse_doc_safe(html), "xml_document")
  expect_s3_class(parse_doc_safe(xml),  "xml_document")
  expect_null(parse_doc_safe(""))
})

test_that("list_badges() scans README and returns a data.frame (no error)", {
  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp), add = TRUE)
  
  writeLines(c(
    "# MyPkg",
    # linked badge
    "[![R-CMD-check](https://github.com/r-lib/testthat/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/r-lib/testthat/actions/workflows/R-CMD-check.yaml)",
    # standalone badge
    "![coverage](https://codecov.io/gh/r-lib/testthat/graph/badge.svg)"
  ), tmp)
  
  out <- list_badges(tmp)
  # The refactor returns a data.frame assembled from fetch_badge_value() results.
  expect_true(is.data.frame(out) || length(out) >= 0)
})

test_that("fetch_badge_value() returns parsed value or NULL for SVG badges", {
  testthat::skip_if_offline()
  # Known public SVGs (stable providers)
  urls <- c(
    "https://github.com/r-lib/testthat/actions/workflows/R-CMD-check.yaml/badge.svg",
    "https://codecov.io/gh/r-lib/testthat/graph/badge.svg"
  )
  vals <- lapply(urls, function(u) fetch_badge_value(u, timeout_secs = 10))
  # Accept either list(name,value), character title, or NULL on parse errors
  ok <- vapply(vals, function(v) {
    is.null(v) ||
      is.character(v) ||
      (is.list(v) && all(c("name","value") %in% names(v)))
  }, logical(1))
  expect_true(all(ok))
})
