test_that("skip_if_repo_unavailable passes through when repo is reachable", {
  withr::local_envvar(NOT_CRAN = "true")
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle) list(status_code = 200L),
    .package = "curl"
  )
  result <- skip_if_repo_unavailable("https://cran.r-project.org")
  expect_true(result)
})
test_that("skip_if_repo_unavailable skips when repo is unreachable", {
  withr::with_options(list(repos = c(CRAN = "http://localhost:19999")), {
    expect_condition(
      skip_if_repo_unavailable(),
      class = "skip",
      regexp = "Repository unavailable"
    )
  })
})
test_that("skip_if_repo_unavailable skips when no repo is configured", {
  withr::with_options(list(repos = c(CRAN = "@CRAN@")), {
    expect_condition(
      skip_if_repo_unavailable(),
      class = "skip",
      regexp = "No CRAN repo configured"
    )
  })
})
test_that("skip_if_repo_unavailable skips when repo is NULL", {
  withr::with_options(list(repos = c(CRAN = NULL)), {
    expect_condition(
      skip_if_repo_unavailable(repo = NULL),
      class = "skip",
      regexp = "No CRAN repo configured"
    )
  })
})

test_that("skip_if_repo_unavailable skips when repo is NA_character_", {
  expect_condition(
    skip_if_repo_unavailable(repo = NA_character_),
    class = "skip",
    regexp = "No CRAN repo configured"
  )
})
test_that("skip_if_repo_unavailable skips when repo is a zero-length character vector", {
  expect_condition(
    skip_if_repo_unavailable(repo = character(0)),
    class = "skip",
    regexp = "No CRAN repo configured"
  )
})

test_that("skip_if_repo_unavailable probes the default PACKAGES.gz url built from repo", {
  withr::local_envvar(NOT_CRAN = "true")
  seen <- NULL
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle) {
      seen <<- url
      list(status_code = 200L)
    },
    .package = "curl"
  )
  skip_if_repo_unavailable(repo = "https://example.org/")
  expect_identical(seen, "https://example.org/src/contrib/PACKAGES.gz")
})

test_that("skip_if_repo_unavailable passes when an explicit url returns status < 400", {
  withr::local_envvar(NOT_CRAN = "true")
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle) list(status_code = 200L),
    .package = "curl"
  )
  expect_true(skip_if_repo_unavailable(url = "https://cran.r-project.org/web/packages/"))
})

test_that("skip_if_repo_unavailable skips when an explicit url returns status >= 400", {
  withr::local_envvar(NOT_CRAN = "true")
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle) list(status_code = 404L),
    .package = "curl"
  )
  expect_condition(
    skip_if_repo_unavailable(url = "https://cran.r-project.org/web/packages/"),
    class = "skip",
    regexp = "Repository unavailable: https://cran.r-project.org/web/packages/"
  )
})

test_that("skip_if_repo_unavailable skips when the curl request errors", {
  withr::local_envvar(NOT_CRAN = "true")
  local_mocked_bindings(
    curl_fetch_memory = function(url, handle) stop("Timeout was reached"),
    .package = "curl"
  )
  expect_condition(
    skip_if_repo_unavailable(url = "https://cran.r-project.org/web/packages/"),
    class = "skip",
    regexp = "Repository unavailable"
  )
})

test_that("skip_if_repo_unavailable rejects an empty url", {
  withr::local_envvar(NOT_CRAN = "true")
  expect_error(skip_if_repo_unavailable(url = ""), "url")
})

test_that("skip_if_repo_unavailable uses base url() when curl is unavailable", {
  withr::local_envvar(NOT_CRAN = "true")
  mockery::stub(skip_if_repo_unavailable, "requireNamespace", function(...) FALSE)
  mockery::stub(skip_if_repo_unavailable, "base::url", function(...) "fake-con")
  mockery::stub(skip_if_repo_unavailable, "base::readBin", function(...) raw(1))
  mockery::stub(skip_if_repo_unavailable, "base::close", function(...) invisible(NULL))
  expect_true(skip_if_repo_unavailable(url = "https://cran.r-project.org/web/packages/"))
})

test_that("skip_if_repo_unavailable skips when base url() errors", {
  withr::local_envvar(NOT_CRAN = "true")
  mockery::stub(skip_if_repo_unavailable, "requireNamespace", function(...) FALSE)
  mockery::stub(skip_if_repo_unavailable, "base::url", function(...) stop("cannot open URL"))
  expect_condition(
    skip_if_repo_unavailable(url = "https://cran.r-project.org/web/packages/"),
    class = "skip",
    regexp = "Repository unavailable"
  )
})
