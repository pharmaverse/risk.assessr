# Check if a Package Exists on CRAN

This function checks if a given package is available on CRAN.

## Usage

``` r
check_cran_package(package_name)
```

## Arguments

- package_name:

  A character string specifying the name of the package to check.

## Value

A logical value: \`TRUE\` if the package exists on CRAN, \`FALSE\`
otherwise.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check if the package "ggplot2" exists on CRAN
check_cran_package("ggplot2")
} # }
```
