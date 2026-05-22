# Check and Fetch CRAN Package

This function checks if a package exists on CRAN and retrieves the
corresponding package URL and version details. If a specific version is
not provided, the latest version is used.

## Usage

``` r
check_and_fetch_cran_package(package_name, package_version = NULL)
```

## Arguments

- package_name:

  A character string specifying the name of the package to check and
  fetch.

- package_version:

  An optional character string specifying the version of the package to
  fetch. Defaults to \`NULL\`.

## Value

A list with one of the following structures:

- package_url:

  Character string; the URL to download the package tarball.

- last_version:

  A named list with `version` and `date` for the latest available
  version.

- version:

  Character string; the requested version (or `NULL` if not specified).

- all_versions:

  A list of named lists, each with `version` and `date`, representing
  all available versions.

## Examples

``` r
if (FALSE) { # \dontrun{
# Check and fetch a specific version of "ggplot2"
result <- check_and_fetch_cran_package("ggplot2", package_version = "3.3.5")
print(result)
} # }
```
