# Get Internal Package URL

This function retrieves the URL of an internal package on Sanofi Mirror,
its latest version, and a list of all available versions.

## Usage

``` r
get_internal_package_url(package_name, version = NULL, base_url = NULL)
```

## Arguments

- package_name:

  A character string specifying the name of the package.

- version:

  An optional character string specifying the version of the package.
  Defaults to \`NULL\`, in which case the latest version will be used.

- base_url:

  A character string specifying the base URL of the internal package
  manager.

## Value

A list containing: - \`url\`: A character string of the package URL (or
\`NULL\` if not found). - \`last_version\`: A list with \`version\` and
\`date\` of the latest version (or \`NULL\`). - \`version\`: The version
used to generate the URL (or \`NULL\`). - \`all_versions\`: A list of
all available versions, each as a list with \`version\` and \`date\`.

## Examples

``` r
if (FALSE) { # \dontrun{
result <- get_internal_package_url("internalpackage", version = "1.0.1")
print(result)
} # }
```
