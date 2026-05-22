# Get CRAN Daily Downloads for a Package

Retrieves daily CRAN download counts over the past years for a given
package, including cumulative downloads.

## Usage

``` r
get_package_download_cran(pkg, years = 1)
```

## Arguments

- pkg:

  Character string, name of the CRAN package.

- years:

  integer, number of past years (default 1) for historical

## Value

A data frame with columns: `date`, `count`, and `cumulative_downloads`.

## Examples

``` r
if (FALSE) { # \dontrun{
  get_package_download_cran("ggplot2")
  # Example output:
  #          date  count cumulative_downloads
  # 1 2025-04-22  78379           20073615
  # 2 2025-04-21  63195           19995236
  # 3 2025-04-20  42119           19932041
  # 4 2025-04-19  40848           19889922
  # 5 2025-04-18  54914           19849074
  # 6 2025-04-17  86273           19794160
  # 7 2025-04-16  80201           19707887
} # }
```
