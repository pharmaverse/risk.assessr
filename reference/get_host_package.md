# Extract and Validate Package Hosting Information

This function retrieves hosting links for an R package from various
sources such as GitHub, CRAN, internal repositories, or Bioconductor.

## Usage

``` r
get_host_package(pkg_name, pkg_version, pkg_source_path)
```

## Arguments

- pkg_name:

  Character. The name of the package.

- pkg_version:

  Character. The version of the package.

- pkg_source_path:

  Character. The file path to the package source directory containing
  the DESCRIPTION file.

## Value

A list containing the following elements:

\- \`github_links\`: GitHub links related to the package. -
\`cran_links\`: CRAN links - \`internal_links\`: internal repository
links. - \`bioconductor_links\`: Bioconductor links

If links are found, return empty or NULL.

## Details

The function extracts hosting links by: 1. Parsing the \`DESCRIPTION\`
file for GitHub and BugReports URLs. 2. Checking if the package is valid
on CRAN and others host repository

If no links are found in the \`DESCRIPTION\` file, returns \`NULL\`

## Examples

``` r
if (FALSE) { # \dontrun{
result <- get_host_package(pkg_name, pkg_version, pkg_source_path)
print(result)
} # }
```
