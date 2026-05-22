# Retrieve GitHub Commits as Weekly Counts (using curl)

This function fetches all commits from a specified GitHub repository
using the GitHub API and returns a data frame with weekly commit counts.

## Usage

``` r
get_commits_since(owner, repo, years = 1)
```

## Arguments

- owner:

  Character. The GitHub username or organization that owns the
  repository.

- repo:

  Character. The name of the GitHub repository.

- years:

  Numeric. Number of years to look back from today's date (default is
  1).

## Value

A data frame with four columns:

- week_start:

  Start date of the week (class `Date`).

- year:

  Year of the commits.

- month:

  Month of the commits.

- n_commits:

  Number of commits during the week.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get commit counts for the past year
get_commits_since(owner = "tidyverse", repo = "ggplot2")
} # }
```
