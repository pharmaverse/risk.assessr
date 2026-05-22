# Retrieve the List of CRAN Packages (Internal)

Downloads and caches the current list of packages available on CRAN.

## Usage

``` r
cran_packages(cache = TRUE)
```

## Arguments

- cache:

  Logical. If `TRUE` (default), the result is cached using
  [`memoise::memoise()`](https://memoise.r-lib.org/reference/memoise.html)
  with a timeout of 30 minutes to avoid repeated downloads. If `FALSE`,
  the metadata is fetched directly from CRAN each time the function is
  called.

## Value

A matrix of package metadata similar to the output of
[`utils::available.packages()`](https://rdrr.io/r/utils/available.packages.html),
with package names as row names.

## Details

The function downloads the `packages.rds` file from the CRAN website,
which contains metadata about all available packages. The result is
cached using
[`memoise::memoise()`](https://memoise.r-lib.org/reference/memoise.html)
with a timeout of 30 minutes.

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloads packages.rds from CRAN (needs network).
pkgs <- cran_packages()
head(rownames(pkgs))
} # }
```
