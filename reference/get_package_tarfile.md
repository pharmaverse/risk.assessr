# Download R Package Source Tarball

Downloads the source tarball (.tar.gz) for a specified R package from
CRAN, Bioconductor, or an internal repository fallback.

## Usage

``` r
get_package_tarfile(package_name, version = NULL, repos = getOption("repos"))
```

## Arguments

- package_name:

  Character string specifying the name of the package to download.

- version:

  Optional character string specifying the version of the package. If
  NULL (default), the latest available version will be downloaded.

- repos:

  Optional character vector of repository URLs to use. If NULL
  (default), the current repositories set in options() will be used.

## Value

Character string with the path to the downloaded tarball file, or NULL
if the download was unsuccessful.

## Examples

``` r
if (FALSE) { # \dontrun{
# Download the latest version of dplyr
tarball_path <- get_package_tarfile("dplyr")

# Download a specific version
tarball_path <- get_package_tarfile("dplyr", version = "1.0.0")

# Use a specific repository
tarball_path <- get_package_tarfile("dplyr", repos = "https://cloud.r-project.org")
} # }
```
