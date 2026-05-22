# Download and Parse Dependencies of an R Package

Downloads a package from a repository, extracts it, and parses
dependencies from the DESCRIPTION file.

## Usage

``` r
download_and_parse_dependencies(
  package_name,
  version = NA,
  get_license = FALSE
)
```

## Arguments

- package_name:

  Name of the package to download.

- version:

  Package version to download (default: \`NA\` for latest).

- get_license:

  Whether to extract license information (default: \`FALSE\`).

## Value

When \`get_license = FALSE\`, a data frame with columns \`package\`,
\`type\`, and \`parent_package\`. When \`get_license = TRUE\`, a list
with: - \`dependencies\`: Data frame of direct dependencies. -
\`license\`: License of the specified package only (not dependencies).
Returns \`NA\` if not found.

## Details

The \`license\` field refers only to the package specified by
\`package_name\`, not its dependencies. Use \`build_dependency_tree()\`
or \`fetch_all_dependencies()\` with \`get_license = TRUE\` for full
license information.

## Examples

``` r
if (FALSE) { # \dontrun{
download_and_parse_dependencies("dplyr")
download_and_parse_dependencies("dplyr", get_license = TRUE)
} # }
```
