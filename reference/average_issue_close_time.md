# Calculate Average Time to Close GitHub Issues

This function uses the GitHub API to retrieve closed issues from a
repository and calculates the average time (in hours) it took to close
them, excluding pull requests.

## Usage

``` r
average_issue_close_time(
  owner,
  repo,
  max_pages = 10,
  per_page = 100,
  headers = c(Accept = "application/vnd.github.v3+json")
)
```

## Arguments

- owner:

  Character. GitHub organization or username.

- repo:

  Character. Repository name.

- max_pages:

  Integer. Maximum number of API result pages to query. Each page can
  contain up to \`per_page\` issues. Default is 10.

- per_page:

  Integer. Number of issues to request per page (max 100). Default is
  100.

- headers:

  Named character vector of HTTP headers to send with the API request.
  Default sets GitHub API version.

## Value

Numeric. Average time in hours to close issues, or \`NA\` if no closed
issues were found.

## Examples

``` r
if (FALSE) { # \dontrun{
average_issue_close_time("tidyverse", "ggplot2")
} # }
```
