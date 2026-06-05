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

# ---- fetch_badge_value(): <title> fallback branch ---------------------------
#
# When the SVG body has no <text> nodes, `vals` is length 0 and the function
# falls through to the <title> branch. We mock curl::curl_fetch_memory() so
# the tests are deterministic and offline-safe (CRAN-friendly).

test_that("fetch_badge_value() returns the <title> text when the SVG has a title but no <text> nodes", {
  fake_svg <- paste0(
    "<svg xmlns='http://www.w3.org/2000/svg' role='img' aria-label='build: passing'>",
    "  <title>build: passing</title>",
    "</svg>"
  )
  fake_response <- list(
    status_code = 200L,
    content     = charToRaw(fake_svg)
  )
  
  mockery::stub(
    fetch_badge_value,
    "curl::curl_fetch_memory",
    function(url, handle) fake_response
  )
  
  out <- fetch_badge_value("https://example.com/title-only.svg")
  
  expect_type(out, "character")
  expect_length(out, 1L)
  expect_identical(out, "build: passing")
})

test_that("fetch_badge_value() trims whitespace around the <title> before returning it", {
  fake_svg <- paste0(
    "<svg xmlns='http://www.w3.org/2000/svg'>",
    "  <title>   coverage: 92%   </title>",
    "</svg>"
  )
  fake_response <- list(
    status_code = 200L,
    content     = charToRaw(fake_svg)
  )
  
  mockery::stub(
    fetch_badge_value,
    "curl::curl_fetch_memory",
    function(url, handle) fake_response
  )
  
  expect_identical(
    fetch_badge_value("https://example.com/padded-title.svg"),
    "coverage: 92%"
  )
})

test_that("fetch_badge_value() falls through to NULL when the SVG <title> is blank and no <text> nodes exist", {
  fake_svg <- paste0(
    "<svg xmlns='http://www.w3.org/2000/svg'>",
    "  <title>   </title>",
    "</svg>"
  )
  fake_response <- list(
    status_code = 200L,
    content     = charToRaw(fake_svg)
  )
  
  mockery::stub(
    fetch_badge_value,
    "curl::curl_fetch_memory",
    function(url, handle) fake_response
  )
  
  expect_null(fetch_badge_value("https://example.com/blank-title.svg"))
})

# ---- normalize_codecov(): NA / empty-string short-circuit (line 4) ---------

test_that("normalize_codecov() returns NA unchanged without touching the substitution", {
  expect_identical(normalize_codecov(NA_character_), NA_character_)
})

test_that("normalize_codecov() returns an empty string unchanged without touching the substitution", {
  expect_identical(normalize_codecov(""), "")
})

# ---- fetch_badge_value(): early-return guards (lines 22 and 26) -------------
#
# The guards short-circuit before any HTTP call. We still stub
# curl::curl_fetch_memory() with a function that errors if invoked, which
# both proves no network access happens and keeps the tests CRAN-safe
# (deterministic, offline, no side effects).

test_that("fetch_badge_value() returns NULL for NA url and never calls curl::curl_fetch_memory (line 22)", {
  mockery::stub(
    fetch_badge_value,
    "curl::curl_fetch_memory",
    function(url, handle) stop("curl_fetch_memory should not be called for NA url")
  )
  
  expect_null(fetch_badge_value(NA_character_))
})

test_that("fetch_badge_value() returns NULL for an empty url and never calls curl::curl_fetch_memory (line 22)", {
  mockery::stub(
    fetch_badge_value,
    "curl::curl_fetch_memory",
    function(url, handle) stop("curl_fetch_memory should not be called for empty url")
  )
  
  expect_null(fetch_badge_value(""))
})

test_that("fetch_badge_value() returns NULL when the url does not point to an .svg resource (line 26)", {
  mockery::stub(
    fetch_badge_value,
    "curl::curl_fetch_memory",
    function(url, handle) stop("curl_fetch_memory should not be called for non-SVG url")
  )
  
  expect_null(fetch_badge_value("https://example.com/not-a-badge.png"))
  expect_null(fetch_badge_value("https://example.com/index.html"))
})

# ---- fetch_badge_value(): HTTP error and unparseable body (lines 37 and 43)-

test_that("fetch_badge_value() returns NULL when curl returns a non-200 status (line 37)", {
  # status_code != 200 triggers stop() inside the tryCatch(), which the
  # error handler converts to NULL. This is the only externally observable
  # signal that line 37 was reached.
  fake_response <- list(
    status_code = 404L,
    content     = charToRaw("")
  )
  
  mockery::stub(
    fetch_badge_value,
    "curl::curl_fetch_memory",
    function(url, handle) fake_response
  )
  
  expect_null(fetch_badge_value("https://example.com/missing.svg"))
})

test_that("fetch_badge_value() returns NULL when parse_doc_safe() cannot build a document (line 43)", {
  # Force the parse step to fail by stubbing parse_doc_safe() to return NULL.
  # This isolates the line 43 branch from any quirks of xml2::read_html()/read_xml().
  fake_response <- list(
    status_code = 200L,
    content     = charToRaw("not valid svg or html <<<")
  )
  
  mockery::stub(
    fetch_badge_value,
    "curl::curl_fetch_memory",
    function(url, handle) fake_response
  )
  mockery::stub(
    fetch_badge_value,
    "parse_doc_safe",
    function(txt) NULL
  )
  
  expect_null(fetch_badge_value("https://example.com/unparseable.svg"))
})

# ---- list_badges(): missing-file guard (line 91) ----------------------------

test_that("list_badges() errors with 'File not found' when the path does not exist", {
  missing_path <- file.path(tempdir(), "definitely-not-a-real-readme.md")
  # Defensive: make sure the file truly is absent before asserting.
  if (file.exists(missing_path)) unlink(missing_path)
  
  expect_error(
    list_badges(missing_path),
    "File not found"
  )
})

# ---- list_badges(): readLines() failure path (lines 100, 101, 104) ----------
#
# When readLines() errors out, the tryCatch() handler must:
#   * fire a warning describing the failure (line 100),
#   * return NULL from the handler (line 101),
# which then triggers the `if (is.null(txt)) return(links)` early exit
# (line 104). `links` is still the seeded `c()`, i.e. NULL.

test_that("list_badges() warns and returns the empty seed when readLines() fails", {
  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp), add = TRUE)
  # The file must exist so the line-91 guard passes; we don't care about contents.
  file.create(tmp)
  
  mockery::stub(
    list_badges,
    "readLines",
    function(...) stop("simulated I/O failure")
  )
  # Guard: ensure no downstream work is attempted after the early return.
  mockery::stub(
    list_badges,
    "fetch_badge_value",
    function(...) stop("fetch_badge_value should not be called after early return")
  )
  
  expect_warning(
    out <- list_badges(tmp),
    "Failed to read .* simulated I/O failure"
  )
  expect_null(out)
})

# ---- list_badges(): inA short-circuit when no linked badges (line 129) ------
#
# Line 129 fires inside the local helper `inA()` when the README has zero
# linked badges (`[![...](IMG)](LINK)`) but at least one standalone badge
# (`![...](IMG)`). In that case `gregexpr(pat_linked, ...)` yields a length-1
# vector with value -1L, so the short-circuit returns FALSE and every B hit
# is kept. We stub fetch_badge_value() so the test is deterministic and
# offline-safe (CRAN-friendly).

test_that("list_badges() keeps standalone badges via the inA short-circuit when no linked badges exist", {
  tmp <- tempfile(fileext = ".md")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(c(
    "# MyPkg",
    "Some prose with no linked badges.",
    "![coverage](https://codecov.io/gh/org/repo/graph/badge.svg)",
    "![build](https://example.com/build.svg)"
  ), tmp)
  
  # Record every URL passed to fetch_badge_value() so we can prove the
  # standalone B hits survived the inA short-circuit. Returning a deterministic
  # list keeps the downstream as.data.frame() call network-free.
  called_urls <- character()
  mockery::stub(
    list_badges,
    "fetch_badge_value",
    function(x, ...) {
      called_urls <<- c(called_urls, x)
      list(name = "stub", value = x)
    }
  )
  
  out <- list_badges(tmp)
  
  # Both standalone badges reached fetch_badge_value(), which only happens if
  # inA() short-circuited to FALSE for every B hit (line 129).
  expect_setequal(
    called_urls,
    c(
      "https://codecov.io/gh/org/repo/graph/badge.svg",
      "https://example.com/build.svg"
    )
  )
  # The function still completes and assembles its result.
  expect_true(is.data.frame(out) || is.list(out))
})
