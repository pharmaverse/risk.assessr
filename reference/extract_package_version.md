# Extract the Installed Version of a Package

This function retrieves the installed version of a specified R package.
If the package is not installed, returns \`NA\`.

## Usage

``` r
extract_package_version(package_name)
```

## Arguments

- package_name:

  A character string specifying the name of the package.

## Value

A character string representing the installed package version, or \`NA\`
if the package is not found.

## Examples

``` r
if (FALSE) { # \dontrun{
extract_package_version("dplyr")
# 1.1.4
} # }
```
