test_that("skip_if_repo_unavailable passes through when repo is reachable", {
  skip_on_cran()
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
