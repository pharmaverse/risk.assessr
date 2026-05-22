# Get CRAN Package URL

This function constructs the CRAN package URL for a specified package
and version.

## Usage

``` r
get_cran_package_url(package_name, version, last_version, all_versions)
```

## Arguments

- package_name:

  A character string specifying the name of the package.

- version:

  An optional character string specifying the version of the package. If
  \`NULL\`, the latest version is assumed.

- last_version:

  A named list with elements version and date, representing the latest
  available version and its publication date.

- all_versions:

  A list of named lists, each with elements version and date,
  representing all known versions of the package and their publication
  dates.

## Value

A character string containing the URL to download the package tarball,
or "No valid URL found" if the version is not found in the list of
available versions.

## Examples

``` r
if (FALSE) { # \dontrun{
# Example data structure
last_version <- list(version = "1.0.10", date = "2024-01-01")
all_versions <- list(
  list(version = "1.0.0", date = "2023-01-01"),
  list(version = "1.0.10", date = "2024-01-01")
)

# Get the URL for the latest version of "dplyr"
url <- get_cran_package_url("dplyr", NULL, last_version, all_versions)
print(url)
} # }
```
