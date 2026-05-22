# List badges image URLs from a local README

Scans a local README (Markdown) and returns badge image URLs.

## Usage

``` r
list_badges(path)
```

## Arguments

- path:

  Character scalar; path to a local README file (e.g., "README.md").

## Value

data.frame with badge info

## Examples

``` r
if (FALSE) { # \dontrun{
tmp <- tempfile(fileext = ".md")
writeLines(c(
  "# MyPkg",
  "![build](build-status.svg)",
  "![cov](coverage.svg)"
), tmp)
out <- list_badges(tmp)
print(out)
} # }
```
