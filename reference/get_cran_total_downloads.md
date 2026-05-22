# Get CRAN Total or Recent Downloads for a Package

Retrieves either all-time total downloads or the total from the last
\`n\` full months for a given CRAN package.

## Usage

``` r
get_cran_total_downloads(pkg, months = NULL)
```

## Arguments

- pkg:

  Character string, the name of the CRAN package.

- months:

  Integer. If NULL, returns all-time total; otherwise, returns total
  from the last \`months\` full months (excluding current).

## Value

An integer: total number of downloads.

## Details

Similar data can be obtained via:

https://cranlogs.r-pkg.org/badges/grand-total/ggplot2
https://cranlogs.r-pkg.org/badges/last-month/ggplot2

## Examples

``` r
if (FALSE) { # \dontrun{
  get_cran_total_downloads("ggplot2")        # all-time total
  # 160776616

  get_cran_total_downloads("ggplot2", 3)     # last 3 full months
  # 4741707

  get_cran_total_downloads("ggplot2", 12)    # last 12 full months
  # 19878885
} # }
```
