mock_curl_success <- function(url, handle) {
  if (grepl("/commits", url)) {
    commits <- replicate(10, list(sha = "mocksha"), simplify = FALSE)
    content <- jsonlite::toJSON(commits, auto_unbox = TRUE)
  } else if (grepl("/repos/", url)) {
    repo <- list(
      created_at = "2015-06-17T09:29:49Z",
      stargazers_count = 5674,
      forks_count = 2040,
      open_issues_count = 42
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
      open_issues_count = 42
    )
    content <- jsonlite::toJSON(repo, auto_unbox = TRUE)
    return(list(content = charToRaw(content)))
  }
}

# get_github_data

test_that("Valid repository returns correct data", {
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl_success)
  result <- get_github_data("tidyverse", "ggplot2")
  
  expect_type(result, "list")
  expect_named(result, c('created_at', 'stars', 'forks', 'date', 'recent_commits_count', 'open_issues'))
  expect_equal(result$created_at, "2015-06-17")
  expect_equal(result$stars, 5674)
  expect_equal(result$forks, 2040)
  expect_equal(result$open_issues, 42)
  expect_equal(result$recent_commits_count, 10) 
})

test_that("Invalid owner returns empty response", {
  result <- get_github_data("", "ggplot2")
  expect_type(result, "list")
  expect_named(result, c('created_at', 'stars', 'forks', 'date', 'recent_commits_count', 'open_issues'))
  expect_null(result$created_at)
  expect_null(result$stars)
  expect_null(result$forks)
  expect_null(result$recent_commits_count)
  expect_null(result$open_issues)
})

test_that("Non-existent repository returns empty response on API failure", {
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl_failure)
  result <- get_github_data("tidyverse", "non_existent_repo")
  
  expect_null(result$created_at)
  expect_null(result$stars)
  expect_null(result$forks)
  expect_null(result$recent_commits_count)
  expect_null(result$open_issues)
})

test_that("Commits endpoint failure returns zero recent commits", {
  mockery::stub(get_github_data, "curl::curl_fetch_memory", mock_curl_commits_failure)
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