# Fetch GitHub Repository Data

This function retrieves metadata about a GitHub repository, including
creation date, stars, forks, and the number of recent commits within the
last 30 days.

## Usage

``` r
get_github_data(owner, repo)
```

## Arguments

- owner:

  A character string specifying the owner of the repository.

- repo:

  A character string specifying the name of the repository.

  A GitHub Personal Access Token (PAT) will be needed for some requests
  or to help with the rate limit. Use Sys.setenv(GITHUB_TOKEN =
  "personal_access_token") or store your token in a .Renviron file. The
  token is passed via the \`Authorization\` header only if
  \`Sys.getenv("GITHUB_TOKEN")\` is non-empty.

## Value

A list containing: - \`created_at\`: Creation date of the repository. -
\`stars\`: Number of stars. - \`forks\`: Number of forks. - \`date\`:
Acquisition date (YYYY-MM-DD). - \`recent_commits_count\`: Number of
commits in the last 30 days. - \`open_issues\`: Number of open issues.

## Details

Repository data is fetched using the GitHub API via \`curl\` and
\`jsonlite\`.

## Examples

``` r
if (FALSE) { # \dontrun{
result <- get_github_data("tidyverse", "ggplot2")
print(result)
} # }
```
