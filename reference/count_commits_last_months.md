# Count Commits in the Last Months

Counts the total number of commits from the last \`months\` months using
a data frame with weekly commit data (column \`week_start\`).

## Usage

``` r
count_commits_last_months(df, months = 1, today = Sys.Date())
```

## Arguments

- df:

  A data frame with \`week_start\` (Date) and \`n_commits\` (int)
  columns.

- months:

  Integer. Number of months to look back (default is 1).

- today:

  today's date.default is Sys.Date()

## Value

Integer. Total number of commits in the time window.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- get_commits_since("tidyverse", "ggplot2", years = 1)
count_commits_last_months(df, months = 3)
} # }
```
