# Parse Dependencies from a Package DESCRIPTION File

This function extracts and returns the dependencies from the DESCRIPTION
file of an R package, focusing on the \`Imports\` field.

## Usage

``` r
parse_dcf_dependencies_version(path)
```

## Arguments

- path:

  A character string specifying the path to the package directory
  containing the DESCRIPTION file.

## Value

A data frame with columns: - \`package\`: The name of the imported
package. - \`type\`: The type of dependency (e.g., "Imports").

## Examples

``` r
if (FALSE) { # \dontrun{
parse_dcf_dependencies_version("/path/to/package")
} # }
```
