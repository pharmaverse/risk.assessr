# Get Package Versions

This function retrieves all available versions of a package, including
the latest version, by parsing the provided version table and querying
the RStudio Package Manager.

## Usage

``` r
get_versions(table, package_name)
```

## Arguments

- table:

  A list of parsed package data (e.g., from \`parse_html_version()\`),
  where each element contains package details such as
  \`package_version\` and \`date\`.

- package_name:

  A character string specifying the name of the package to fetch
  versions for.

## Value

A list with the following elements:

- all_versions:

  A list of named lists, each containing:

  version

  :   The version number of the package.

  date

  :   The associated publication date as a string.

- last_version:

  A named list containing the latest version of the package with:

  version

  :   The latest version number.

  date

  :   The publication date of the latest version.

  May be `NULL` if the API call fails.

## Examples

``` r
if (FALSE) { # \dontrun{
# Define the input table
table <- list(
  list(
    package_name = "here",
    package_version = "0.1",
    link = "here_0.1.tar.gz",
    date = "2017-05-28 08:13",
    size = "3.5K"
  ),
  list(
    package_name = "here",
    package_version = "1.0.0",
    link = "here_1.0.0.tar.gz",
    date = "2020-11-15 18:10",
    size = "32K"
  )
)

result <- get_versions(table, "here")
print(result)
} # }
```
