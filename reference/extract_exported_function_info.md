# Extract Exported Function Metadata from an R Package

This internal utility function analyzes the namespace of an R package
and extracts metadata about its exported functions, including
classification into S3, S4, S7, and regular functions.

## Usage

``` r
extract_exported_function_info(.pkg_source_path, package_name)
```

## Arguments

- .pkg_source_path:

  Character. Path to the source directory of the R package.

- package_name:

  Character. Name of the package (typically the folder name or actual
  package name).

## Value

A tibble with columns: \`exported_function\`, \`class\`,
\`function_type\`, \`function_body\`, and \`where\`.
