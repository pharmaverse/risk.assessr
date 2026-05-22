# Parse Package Information from CRAN Archive

This function retrieves the package archive information from the CRAN
Archive.

## Usage

``` r
parse_package_info(name)
```

## Arguments

- name:

  A character string specifying the name of the package to fetch
  information for.

## Value

A character string containing the raw HTML content of the package
archive page, or \`NULL\` if the request fails or the package is not
found.

## Examples

``` r
if (FALSE) { # \dontrun{
# Fetch package archive information for "dplyr"
parse_package_info("dplyr")

} # }
```
