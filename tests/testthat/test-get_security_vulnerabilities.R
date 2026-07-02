# a parsed OSV response with two vulnerabilities of different types
fake_parsed_osv <- list(
  vulns = list(
    list(
      id        = "RSEC-2023-6",
      summary   = "Denial of Service (DoS) vulnerability",
      details   = "Parsing certain crafted markdown tables can take O(n * n) time.",
      modified  = "2025-05-19T19:43:47.903227Z",
      published = "2023-10-06T05:00:00.600Z",
      affected  = list(
        list(ranges = list(
          list(events = list(
            list(introduced = "0.2"),
            list(fixed = "1.8")
          ))
        ))
      )
    ),
    list(
      id        = "RSEC-2023-7",
      summary   = "Arbitrary Code Execution (ACE) Vulnerability",
      details   = "Integer overflow in table row parsing leading to heap corruption.",
      modified  = "2025-05-19T19:43:48.143066Z",
      published = "2023-10-06T05:00:00.600Z",
      affected  = list(
        list(ranges = list(
          list(events = list(
            list(introduced = "0.2"),
            list(fixed = "1.9.2")
          ))
        ))
      )
    )
  )
)

# build a raw curl response from a list, mimicking curl::curl_fetch_memory
make_osv_resp <- function(obj, status_code = 200) {
  content <- jsonlite::toJSON(obj, auto_unbox = TRUE)
  list(status_code = status_code, content = charToRaw(content))
}

# get_security_vulnerabilities

test_that("vulnerabilities are returned as a data frame with expected columns", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_parsed_osv)
  
  result <- get_security_vulnerabilities("commonmark", "1.7")
  
  expect_s3_class(result, "data.frame")
  expect_named(result, c("id", "summary", "details", "introduced",
                         "fixed", "modified", "published"))
  expect_equal(nrow(result), 2)
  expect_equal(result$summary[1], "Denial of Service (DoS) vulnerability")
  expect_equal(result$summary[2], "Arbitrary Code Execution (ACE) Vulnerability")
  expect_equal(result$introduced[1], "0.2")
  expect_equal(result$fixed[2], "1.9.2")
})

test_that("advisories not affecting the requested version are filtered out", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_parsed_osv)
  
  # version 1.8 is at/after the first advisory's fixed version (1.8) but still
  # before the second advisory's fixed version (1.9.2)
  result <- get_security_vulnerabilities("commonmark", "1.8")
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$id, "RSEC-2023-7")
})

test_that("a version after every fixed release yields an empty data frame", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_parsed_osv)
  
  result <- get_security_vulnerabilities("commonmark", "2.0")
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("all advisories are returned when no version is supplied", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_parsed_osv)
  
  result <- get_security_vulnerabilities("commonmark")
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
})

# an advisory whose only affected metadata is an explicit `versions`
# enumeration in the array form returned by the live OSV query API
fake_versions_array <- list(
  vulns = list(
    list(
      id        = "RSEC-ENUM-ARR",
      summary   = "Enumerated versions (array form)",
      details   = "Affected versions are listed explicitly as an array.",
      modified  = "2025-01-01T00:00:00Z",
      published = "2024-01-01T00:00:00Z",
      affected  = list(
        list(versions = list("0.2", "1.5", "1.7"))
      )
    )
  )
)

# the same advisory but with `versions` as an object keyed by version, the
# shape used by the aggregated r-advisory-database feed
fake_versions_object <- list(
  vulns = list(
    list(
      id        = "RSEC-ENUM-OBJ",
      summary   = "Enumerated versions (object form)",
      details   = "Affected versions are listed explicitly as object keys.",
      modified  = "2025-01-01T00:00:00Z",
      published = "2024-01-01T00:00:00Z",
      affected  = list(
        list(versions = list("0.2" = list(), "1.5" = list(), "1.7" = list()))
      )
    )
  )
)

test_that("version enumeration (array form) is matched by value", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_versions_array)
  
  expect_equal(nrow(get_security_vulnerabilities("pkg", "1.5")), 1)
  expect_equal(nrow(get_security_vulnerabilities("pkg", "1.6")), 0)
})

test_that("version enumeration (object form) is matched by key", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_versions_object)
  
  expect_equal(nrow(get_security_vulnerabilities("pkg", "1.5")), 1)
  expect_equal(nrow(get_security_vulnerabilities("pkg", "1.6")), 0)
})

# an advisory whose affected metadata is range-only (introduced/fixed), with no
# explicit `versions` enumeration, so range comparison is the only matcher
fake_range_only <- list(
  vulns = list(
    list(
      id        = "RSEC-RANGE",
      summary   = "Range-only advisory",
      details   = "Affected versions are described only by an introduced/fixed range.",
      modified  = "2025-01-01T00:00:00Z",
      published = "2024-01-01T00:00:00Z",
      affected  = list(
        list(ranges = list(
          list(events = list(
            list(introduced = "0.2"),
            list(fixed = "1.8")
          ))
        ))
      )
    )
  )
)

# covers line 188: when the supplied version cannot be parsed by
# numeric_version(), `ver` is NULL and the range comparison is skipped via
# `next`, so a range-only advisory cannot be matched and is dropped
test_that("an unparseable version skips range comparison and drops range-only advisories", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_range_only)
  
  result <- get_security_vulnerabilities("pkg", "not-a-version")
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

# also exercises the `is.null(ver)` path with a version string OSV itself uses
# for upstream components (e.g. "0.29.0.gfm.1") that numeric_version() rejects
test_that("an unparseable upstream-style version drops range-only advisories", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_range_only)
  
  result <- get_security_vulnerabilities("pkg", "0.29.0.gfm.1")
  
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

# an advisory whose enumeration contains a version string that
# numeric_version() cannot parse (the upstream-style "gfm" form)
fake_enum_unparseable <- list(
  vulns = list(
    list(
      id        = "RSEC-ENUM-UP",
      summary   = "Enumeration with unparseable version",
      details   = "Affected versions include an upstream-style version string.",
      modified  = "2025-01-01T00:00:00Z",
      published = "2024-01-01T00:00:00Z",
      affected  = list(
        list(versions = list("0.29.0.gfm.1", "1.5"))
      )
    )
  )
)

# confirms the enumeration short-circuit (line 179) matches an unparseable
# version before the range check / is.null(ver) path is reached
test_that("an unparseable version is still matched via explicit enumeration", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", fake_enum_unparseable)
  
  result <- get_security_vulnerabilities("pkg", "0.29.0.gfm.1")
  
  expect_equal(nrow(result), 1)
})

test_that("empty package name returns an empty data frame", {
  result <- get_security_vulnerabilities("")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_named(result, c("id", "summary", "details", "introduced",
                         "fixed", "modified", "published"))
})

test_that("no known vulnerabilities returns an empty data frame", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", list())
  
  result <- get_security_vulnerabilities("safe_pkg", "1.0")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("API failure returns an empty data frame and does not error", {
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", NULL)
  
  result <- get_security_vulnerabilities("commonmark", "1.7")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

# covers line 144: get_event_version() returns NA when a vulnerability record
# has no `affected` element
test_that("a vulnerability without affected ranges yields NA versions", {
  parsed_no_affected <- list(
    vulns = list(
      list(
        id        = "RSEC-2024-1",
        summary   = "NULL pointer dereference vulnerability",
        details   = "A NULL pointer dereference with no affected version range.",
        modified  = "2025-01-01T00:00:00Z",
        published = "2024-01-01T00:00:00Z"
      )
    )
  )
  mockery::stub(get_security_vulnerabilities, "fetch_osv_data", parsed_no_affected)
  
  result <- get_security_vulnerabilities("somepkg", "1.0")
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$summary, "NULL pointer dereference vulnerability")
  expect_true(is.na(result$introduced))
  expect_true(is.na(result$fixed))
})

# fetch_osv_data

test_that("fetch_osv_data returns parsed list on success", {
  mockery::stub(fetch_osv_data, "curl::curl_fetch_memory",
                function(url, handle) make_osv_resp(fake_parsed_osv))
  parsed <- fetch_osv_data("commonmark", "1.7")
  expect_type(parsed, "list")
  expect_length(parsed$vulns, 2)
})

test_that("fetch_osv_data returns NULL on non-200 status", {
  mockery::stub(fetch_osv_data, "curl::curl_fetch_memory",
                function(url, handle) make_osv_resp(list(), status_code = 500))
  expect_message(parsed <- fetch_osv_data("commonmark", "1.7"),
                 "OSV API returned status 500")
  expect_null(parsed)
})

test_that("fetch_osv_data returns NULL when the API is unavailable", {
  mockery::stub(fetch_osv_data, "curl::curl_fetch_memory",
                function(url, handle) stop("Mocked OSV API failure"))
  expect_message(parsed <- fetch_osv_data("commonmark", "1.7"),
                 "Failed to reach OSV API")
  expect_null(parsed)
})

# covers line 39: the query body omits the version when none is supplied
test_that("fetch_osv_data omits the version from the query body when not given", {
  setopt_mock <- mockery::mock(NULL)
  mockery::stub(fetch_osv_data, "curl::new_handle", function(...) NULL)
  mockery::stub(fetch_osv_data, "curl::handle_setheaders", function(...) NULL)
  mockery::stub(fetch_osv_data, "curl::handle_setopt", setopt_mock)
  mockery::stub(fetch_osv_data, "curl::curl_fetch_memory",
                function(url, handle) make_osv_resp(fake_parsed_osv))
  
  parsed <- fetch_osv_data("commonmark")
  
  setopt_args <- mockery::mock_args(setopt_mock)[[1]]
  expect_false(grepl("\"version\"", setopt_args$postfields))
  expect_true(grepl("commonmark", setopt_args$postfields))
  expect_length(parsed$vulns, 2)
})

# covers lines 65-66: the parse error handler reports a message and returns NULL
test_that("fetch_osv_data returns NULL when the response cannot be parsed", {
  mockery::stub(fetch_osv_data, "curl::curl_fetch_memory",
                function(url, handle) make_osv_resp(fake_parsed_osv))
  mockery::stub(fetch_osv_data, "jsonlite::fromJSON",
                function(...) stop("invalid json"))
  
  expect_message(parsed <- fetch_osv_data("commonmark", "1.7"),
                 "Failed to parse OSV response")
  expect_null(parsed)
})
