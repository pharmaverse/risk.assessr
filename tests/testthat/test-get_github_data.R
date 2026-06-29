mock_curl_success <- function(url, handle) {
  if (grepl("/commits", url)) {
    commits <- replicate(10, list(sha = "mocksha"), simplify = FALSE)
    content <- jsonlite::toJSON(commits, auto_unbox = TRUE)
  } else if (grepl("/repos/", url)) {
    repo <- list(
      created_at = "2015-06-17T09:29:49Z",
      stargazers_count = 5674,
      forks_count = 2040,
      open_issues_count = 42,
      average_issue_close_time = 847
    )
    content <- jsonlite::toJSON(repo, auto_unbox = TRUE)
  } else {
    stop("Unknown URL")
  }
  list(content = charToRaw(content))
}

mock_curl_failure <- function(url, handle) {
  stop("Mocked API call failure")
}

mock_curl_commits_failure <- function(url, handle) {
  if (grepl("/commits", url)) {
    stop("Mocked commits API failure")
  } else if (grepl("/repos/", url)) {
    repo <- list(
      created_at = "2015-06-17T09:29:49Z",
      stargazers_count = 5674,
      forks_count = 2040,
      open_issues_count = 42,
      average_issue_close_time = 847
    )
    content <- jsonlite::toJSON(repo, auto_unbox = TRUE)
    return(list(content = charToRaw(content)))
  }
}

# get_github_data

test_that("Valid repository returns correct data", {
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl_success)
  mockery::stub(get_github_data, "average_issue_close_time", 847)
  result <- get_github_data("tidyverse", "ggplot2")
  
  expect_type(result, "list")
  expect_named(result, c('created_at', 'stars', 'forks', 'date', 
                         'recent_commits_count', 'open_issues', 'average_issue_close_time'))
  expect_equal(result$created_at, "2015-06-17")
  expect_equal(result$stars, 5674)
  expect_equal(result$forks, 2040)
  expect_equal(result$open_issues, 42)
  expect_equal(result$recent_commits_count, 10)
  expect_equal(result$average_issue_close_time, 847)
})

test_that("Invalid owner returns empty response", {
  result <- get_github_data("", "ggplot2")
  expect_type(result, "list")
  expect_named(result, c('created_at', 'stars', 'forks', 'date', 
                         'recent_commits_count', 'open_issues', 'average_issue_close_time'))
  expect_null(result$created_at)
  expect_null(result$stars)
  expect_null(result$forks)
  expect_null(result$recent_commits_count)
  expect_null(result$open_issues)
  expect_null(result$average_issue_close_time)
})

test_that("Non-existent repository returns empty response on API failure", {
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl_failure)
  result <- get_github_data("tidyverse", "non_existent_repo")
  
  expect_null(result$created_at)
  expect_null(result$stars)
  expect_null(result$forks)
  expect_null(result$recent_commits_count)
  expect_null(result$open_issues)
  expect_null(result$average_issue_close_time)
})

test_that("Commits endpoint failure returns zero recent commits", {
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl_commits_failure)
  mockery::stub(get_github_data, "average_issue_close_time", 847)
  result <- get_github_data("tidyverse", "ggplot2")
  
  expect_equal(result$created_at, "2015-06-17")
  expect_equal(result$stars, 5674)
  expect_equal(result$forks, 2040)
  expect_equal(result$open_issues, 42)
  expect_equal(result$recent_commits_count, 0)
})

test_that("Handles both repo and commits failure gracefully", {
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl_failure)
  result <- get_github_data("tidyverse", "non_existent_repo")
  
  expect_null(result$created_at)
  expect_null(result$stars)
  expect_null(result$forks)
  expect_null(result$recent_commits_count)
  expect_null(result$open_issues)
})

# Helper: build a curl mock that serves fixed repo data and custom commits JSON
make_repo_commits_mock <- function(commits_json) {
  function(url, handle) {
    if (grepl("/commits", url)) {
      return(list(content = charToRaw(commits_json)))
    }
    repo <- list(
      created_at = "2015-06-17T09:29:49Z",
      stargazers_count = 5674,
      forks_count = 2040,
      open_issues_count = 42
    )
    list(content = charToRaw(jsonlite::toJSON(repo, auto_unbox = TRUE)))
  }
}

test_that("recent_commits_count uses length of sha when commits is a non-data-frame list", {
  # Single JSON object -> parsed as a list (not a data frame) with a sha element
  mock_curl <- make_repo_commits_mock('{"sha":["a","b","c"]}')
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl)
  mockery::stub(get_github_data, "average_issue_close_time", 847)
  
  result <- get_github_data("tidyverse", "ggplot2")
  
  expect_equal(result$recent_commits_count, 3)
})

test_that("recent_commits_count is 0 when commits list has no sha element", {
  # JSON object without a sha field -> list without $sha -> else branch returns 0
  mock_curl <- make_repo_commits_mock('{"message":"No commits in range"}')
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl)
  mockery::stub(get_github_data, "average_issue_close_time", 847)
  
  result <- get_github_data("tidyverse", "ggplot2")
  
  expect_equal(result$recent_commits_count, 0)
})

test_that("recent_commits_count falls back to 0 when counting commits errors", {
  # JSON array of scalars -> atomic vector; `$sha` on an atomic vector errors,
  # exercising the tryCatch error handler.
  mock_curl <- make_repo_commits_mock('["a","b"]')
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl)
  mockery::stub(get_github_data, "average_issue_close_time", 847)
  
  expect_message(
    result <- get_github_data("tidyverse", "ggplot2"),
    "Failed to count recent commits"
  )
  expect_equal(result$recent_commits_count, 0)
})


# average_issue_close_time

mock_curl_closed_issues_success <- function(url, handle) {
  issues <- list(
    list(created_at = "2024-01-01T10:00:00Z", closed_at = "2024-01-02T10:00:00Z"),
    list(created_at = "2024-01-01T08:00:00Z", closed_at = "2024-01-03T08:00:00Z"),
    list(created_at = "2024-01-01T00:00:00Z", closed_at = "2024-01-04T00:00:00Z", `pull_request.url` = "some-url") # excluded
  )
  content <- jsonlite::toJSON(issues, auto_unbox = TRUE)
  list(content = charToRaw(content))
}

mock_curl_issues_empty <- function(url, handle) {
  content <- jsonlite::toJSON(list(), auto_unbox = TRUE)
  list(content = charToRaw(content))
}

mock_curl_issues_not_found <- function(url, handle) {
  issues <- list(
    message = "Not Found",
    documentation_url = "https://docs.github.com/rest/issues/issues#list-repository-issues",
    status = "404"
  )
  content <- jsonlite::toJSON(issues, auto_unbox = TRUE)
  list(content = charToRaw(content))
}


test_that("average_issue_close_time calculates correctly with curl mock", {
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_closed_issues_success)
  
  result <- average_issue_close_time("owner", "repo", max_pages = 1)
  
  expect_equal(result, 36)  # (24h + 48h) / 2
})


test_that("average_issue_close_time calculates correctly with mocked API", {
  mock_gh <- function(endpoint, ..., owner, repo, state, per_page, page) {
    if (grepl("/repos/.+/.+/issues", endpoint)) {
      return(list(
        list(
          created_at = "2024-01-01T10:00:00Z",
          closed_at =  "2024-01-02T10:00:00Z"
        ),
        list(
          created_at = "2024-01-01T08:00:00Z",
          closed_at  = "2024-01-03T08:00:00Z"
        ),
        list(
          created_at = "2024-01-01T00:00:00Z",
          closed_at  = "2024-01-04T00:00:00Z",
          pull_request = list(url = "https://api.github.com/repos/org/repo/pulls/123")
        )
      ))
    }
    stop("Unknown endpoint")
  }
  
  mock_curl <- function(url, handle) {
    issues <- list(
      list(
        created_at = "2024-01-01T10:00:00Z",
        closed_at  = "2024-01-02T10:00:00Z"
      ),
      list(
        created_at = "2024-01-01T08:00:00Z",
        closed_at  = "2024-01-03T08:00:00Z"
      ),
      list(
        created_at = "2024-01-01T00:00:00Z",
        closed_at  = "2024-01-04T00:00:00Z",
        `pull_request.url` = "https://api.github.com/repos/org/repo/pulls/123"
      )
    )
    content <- jsonlite::toJSON(issues, auto_unbox = TRUE)
    list(content = charToRaw(content))
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl)
  
  result <- average_issue_close_time("someowner", "somerepo", max_pages = 1)
  
  # (24h + 48h) / 2 = 36h
  expect_equal(result, 36)
})


test_that("average_issue_close_time returns NA when only pull requests returned", {
  mock_curl_only_pull_requests <- function(url, handle) {
    if (grepl("/issues", url)) {
      issues <- list(
        list(
          created_at = "2024-01-01T00:00:00Z",
          closed_at = "2024-01-02T00:00:00Z",
          `pull_request.url` = "https://api.github.com/repos/org/repo/pulls/123"
        )
      )
      content <- jsonlite::toJSON(issues, auto_unbox = TRUE)
      return(list(content = charToRaw(content)))
    } else {
      stop("Unexpected URL in mock")
    }
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_only_pull_requests)
  
  expect_message(
    result <- average_issue_close_time("owner", "repo", max_pages = 1),
    "No closed issues found",
    fixed = TRUE
  )
  
  expect_true(is.na(result))
})




test_that("average_issue_close_time returns NA when API returns no issues", {
  result <- average_issue_close_time("owner", "repo", max_pages = 1)
  expect_true(is.na(result))
})

test_that("average_issue_close_time handles issues with no pull_request.url column", {
  mock_curl_no_pr_col <- function(url, handle) {
    issues <- list(
      list(created_at = "2024-01-01T00:00:00Z", closed_at = "2024-01-02T00:00:00Z"),
      list(created_at = "2024-01-01T00:00:00Z", closed_at = "2024-01-03T00:00:00Z")
    )
    list(content = charToRaw(jsonlite::toJSON(issues, auto_unbox = TRUE)))
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_no_pr_col)
  result <- average_issue_close_time("owner", "repo", max_pages = 1)
  expect_equal(result, 36)  # (24h + 48h) / 2
})


test_that("average_issue_close_time stops pagination on empty page and returns collected results", {
  page1_json <- jsonlite::toJSON(list(
    list(created_at = "2024-01-01T00:00:00Z", closed_at = "2024-01-02T00:00:00Z")
  ), auto_unbox = TRUE)
  page2_json <- jsonlite::toJSON(list(), auto_unbox = TRUE)
  
  mock_curl_paginated <- mockery::mock(
    list(content = charToRaw(page1_json)),
    list(content = charToRaw(page2_json))
  )
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_paginated)
  result <- average_issue_close_time("owner", "repo", max_pages = 5)
  expect_equal(result, 24)  # 24 hours from page 1
})


test_that("average_issue_close_time breaks and returns NA when curl fetch throws", {
  mock_curl_error <- function(url, handle) stop("connection refused")
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_error)
  expect_message(
    result <- average_issue_close_time("owner", "repo", max_pages = 1),
    "Failed to fetch page"
  )
  expect_true(is.na(result))
})


test_that("average_issue_close_time breaks cleanly when JSON cannot be parsed", {
  mock_curl_bad_json <- function(url, handle) {
    list(content = charToRaw("{{not valid json"))
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_bad_json)
  expect_message(
    result <- average_issue_close_time("owner", "repo", max_pages = 1),
    "Failed to parse page"
  )
  expect_true(is.na(result))
})


test_that("average_issue_close_time returns NA on abuse detection rate limit", {
  mock_curl_rate_limit <- function(url, handle) {
    content <- jsonlite::toJSON(
      list(message = "You have triggered an abuse detection mechanism"),
      auto_unbox = TRUE
    )
    list(content = charToRaw(content))
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_rate_limit)
  expect_message(
    result <- average_issue_close_time("owner", "repo", max_pages = 1),
    "GitHub API rate-limited us"
  )
  expect_true(is.na(result))
})


test_that("average_issue_close_time returns NA on generic GitHub API message", {
  mock_curl_generic_msg <- function(url, handle) {
    content <- jsonlite::toJSON(list(message = "Bad credentials"), auto_unbox = TRUE)
    list(content = charToRaw(content))
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_generic_msg)
  expect_message(
    result <- average_issue_close_time("owner", "repo", max_pages = 1),
    "GitHub returned a message"
  )
  expect_true(is.na(result))
})


test_that("average_issue_close_time returns NA for unexpected non-data-frame response", {
  mock_curl_unexpected <- function(url, handle) {
    list(content = charToRaw(jsonlite::toJSON(TRUE, auto_unbox = TRUE)))
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_unexpected)
  expect_message(
    result <- average_issue_close_time("owner", "repo", max_pages = 1),
    "Issues data is not a data frame"
  )
  expect_true(is.na(result))
})


test_that("average_issue_close_time skips issues with NA timestamps", {
  mock_curl_na_timestamps <- function(url, handle) {
    issues <- list(
      list(created_at = NA,      closed_at = "2024-01-02T00:00:00Z"),
      list(created_at = "2024-01-01T00:00:00Z", closed_at = NA),
      list(created_at = "2024-01-01T00:00:00Z", closed_at = "2024-01-03T00:00:00Z")
    )
    list(content = charToRaw(jsonlite::toJSON(issues, auto_unbox = TRUE)))
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_na_timestamps)
  result <- average_issue_close_time("owner", "repo", max_pages = 1)
  expect_equal(result, 48)  # only the third issue: 48 hours
})


test_that("average_issue_close_time skips issues with malformed date strings", {
  mock_curl_bad_dates <- function(url, handle) {
    issues <- list(
      list(created_at = "not-a-date",           closed_at = "also-not-a-date"),
      list(created_at = "2024-01-01T00:00:00Z", closed_at = "2024-01-02T00:00:00Z")
    )
    list(content = charToRaw(jsonlite::toJSON(issues, auto_unbox = TRUE)))
  }
  
  mockery::stub(average_issue_close_time, "curl::curl_fetch_memory", mock_curl_bad_dates)
  suppressWarnings(
    result <- average_issue_close_time("owner", "repo", max_pages = 1)
  )
  expect_equal(result, 24)  # only the valid issue: 24 hours
})


# commit history get_commits_since

test_that("get_commits_since handles pagination and aggregates weekly commits", {
  # Simulated JSON responses
  mock_commits_page1 <- jsonlite::toJSON(list(
    list(commit = list(author = list(date = "2024-04-01T12:00:00Z"))),
    list(commit = list(author = list(date = "2024-04-02T12:00:00Z")))
  ), auto_unbox = TRUE)
  
  mock_commits_page2 <- jsonlite::toJSON(list(
    list(commit = list(author = list(date = "2024-04-03T12:00:00Z")))
  ), auto_unbox = TRUE)
  
  mock_commits_empty <- jsonlite::toJSON(list(), auto_unbox = TRUE)
  
  mock_curl <- mockery::mock(
    list(content = charToRaw(mock_commits_page1)),
    list(content = charToRaw(mock_commits_page2)),
    list(content = charToRaw(mock_commits_empty))
  )
  
  mockery::stub(get_commits_since, "curl::curl_fetch_memory", mock_curl)
  
  result <- get_commits_since("someowner", "somerepo", years = 1)
  
  expect_s3_class(result, "data.frame")
  expect_true(all(c("week_start", "n_commits") %in% colnames(result)))
  expect_equal(sum(result$n_commits), 3)  # 3 commits across 2 pages
})



test_that("get_commits_since returns empty data frame when no commits", {
  # Simulate GitHub API returning no commits (empty list)
  mock_empty_commits_json <- jsonlite::toJSON(list(), auto_unbox = TRUE)
  
  mock_curl <- mockery::mock(
    list(content = charToRaw(mock_empty_commits_json))  # First page
  )
  
  mockery::stub(get_commits_since, "curl::curl_fetch_memory", mock_curl)
  
  result <- get_commits_since("someowner", "somerepo", years = 1)
  
  expect_equal(nrow(result), 0)
  expect_true(all(c("week_start", "n_commits") %in% colnames(result)))
})


test_that("get_commits_since correctly groups commits by week", {
  # Simulate API response with commits across different weeks
  mock_commits <- list(
    list(commit = list(author = list(date = "2024-03-31T23:59:59Z"))),  # Sunday
    list(commit = list(author = list(date = "2024-04-01T00:00:00Z")))   # Monday
  )
  
  mock_json <- jsonlite::toJSON(mock_commits, auto_unbox = TRUE)
  
  # First call returns data, second returns empty list to stop
  mock_curl <- mockery::mock(
    list(content = charToRaw(mock_json)),
    list(content = charToRaw(jsonlite::toJSON(list(), auto_unbox = TRUE)))
  )
  
  mockery::stub(get_commits_since, "curl::curl_fetch_memory", mock_curl)
  
  result <- get_commits_since("someowner", "somerepo", years = 1)
  
  expect_equal(nrow(result), 2)  # One commit in each week
  expect_equal(sum(result$n_commits), 2)
})


test_that("get_commits_since returns empty data frame when the fetch fails", {
  # curl error on the first page -> message, NULL, loop breaks, empty result
  mockery::stub(
    get_commits_since, "curl::curl_fetch_memory",
    function(url, handle) stop("network down")
  )
  
  expect_message(
    result <- get_commits_since("someowner", "somerepo", years = 1),
    "Failed to fetch page"
  )
  expect_equal(nrow(result), 0)
  expect_true(all(c("week_start", "n_commits") %in% colnames(result)))
})


test_that("get_commits_since returns empty data frame when JSON cannot be parsed", {
  # Response with malformed JSON content -> parse error handler -> NULL -> break
  mock_curl <- mockery::mock(list(content = charToRaw("INVALID{")))
  mockery::stub(get_commits_since, "curl::curl_fetch_memory", mock_curl)
  
  expect_message(
    result <- get_commits_since("someowner", "somerepo", years = 1),
    "Error parsing JSON on page"
  )
  expect_equal(nrow(result), 0)
  expect_true(all(c("week_start", "n_commits") %in% colnames(result)))
})


test_that("get_commits_since returns empty data frame when all commit dates are NA", {
  # Commits present, but dates are null -> parsed as NA -> safeguard returns empty df.
  # JSON null becomes a logical NA column, so as.Date() yields NA dates (no error).
  mock_page1 <- '[{"commit":{"author":{"date":null}}},{"commit":{"author":{"date":null}}}]'
  mock_empty <- jsonlite::toJSON(list(), auto_unbox = TRUE)
  
  mock_curl <- mockery::mock(
    list(content = charToRaw(mock_page1)),
    list(content = charToRaw(mock_empty))
  )
  mockery::stub(get_commits_since, "curl::curl_fetch_memory", mock_curl)
  
  result <- get_commits_since("someowner", "somerepo", years = 1)
  
  expect_equal(nrow(result), 0)
  expect_true(all(c("week_start", "n_commits") %in% colnames(result)))
})


# count commit

df <- data.frame(
  year = c(2025, 2025, 2025, 2025, 2025, 2025, 2025),
  month = c(4, 4, 3, 3, 3, 2, 2),
  n_commits = c(2, 18, 4, 27, 1, 2, 1)
)

mock_today <- as.Date("2025-04-21")

test_that("counts commits for 1 month correctly", {
  result <- count_commits_last_months(df, months = 1, today = mock_today)
  # Should include March + April (4+27+1+2+18) = 52
  expect_equal(result, 52)
})

test_that("counts commits for 2 months correctly", {
  result <- count_commits_last_months(df, months = 2, today = mock_today)
  # Should include February + March + April (all rows) = 55
  expect_equal(result, 55)
})

test_that("returns 0 when no matching months", {
  result <- count_commits_last_months(df, months = 0, today = mock_today)
  # Only April matches exactly
  expect_equal(result, 20)
})


test_that("returns 0 for an empty data frame", {
  empty_df <- data.frame(year = integer(), month = integer(), n_commits = integer())
  result <- count_commits_last_months(empty_df, months = 1, today = mock_today)
  expect_equal(result, 0)
})

test_that("throws an error if required columns are missing", {
  invalid_df <- data.frame(date = as.Date("2025-04-01"), commits = 5)
  expect_error(
    count_commits_last_months(invalid_df, months = 1, today = mock_today),
    "Data frame must have 'year', 'month', and 'n_commits' columns."
  )
})

test_that("counts commits across a year boundary (month wraparound)", {
  # today in January with a 3-month window forces start_month <= 0,
  # exercising the wraparound loop (start_month + 12, start_year - 1).
  wrap_df <- data.frame(
    year = c(2023, 2023),
    month = c(10, 11),
    n_commits = c(5, 3)
  )
  result <- count_commits_last_months(wrap_df, months = 3, today = as.Date("2024-01-15"))
  # Window spans 2023-10 .. 2024-01, so both rows are included: 5 + 3 = 8
  expect_equal(result, 8)
})


# get_repo_owner

test_that("extracts correct owner when link matches package name", {
  links <- c("https://github.com/tidyverse/haven", "https://github.com/other/repo")
  pkg_name <- "haven"
  expect_equal(get_repo_owner(links, pkg_name), "tidyverse")
})

test_that("returns NA when no link matches the package name", {
  links <- c("https://github.com/tidyverse/haven")
  pkg_name <- "dplyr"
  expect_true(is.na(get_repo_owner(links, pkg_name)))
})

test_that("returns NA when links are 'No GitHub link found'", {
  links <- "No GitHub link found"
  pkg_name <- "haven"
  expect_true(is.na(get_repo_owner(links, pkg_name)))
})

test_that("returns NA when links are NULL", {
  links <- NULL
  pkg_name <- "haven"
  expect_true(is.na(get_repo_owner(links, pkg_name)))
})

test_that("handles trailing slash in GitHub link", {
  links <- c("https://github.com/tidyverse/haven/")
  pkg_name <- "haven"
  expect_equal(get_repo_owner(links, pkg_name), "tidyverse")
})

test_that("handles multiple trailing slashes", {
  links <- c("https://github.com/tidyverse/haven///")
  pkg_name <- "haven"
  expect_equal(get_repo_owner(links, pkg_name), "tidyverse")
})