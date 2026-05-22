# Fetch All Dependencies for a Package

This function builds and retrieves the full dependency tree for a given
R package.

## Usage

``` r
fetch_all_dependencies(package_name, get_license = FALSE, max_level = 3)
```

## Arguments

- package_name:

  A character string specifying the name of the package.

- get_license:

  A logical value indicating whether to extract and include license
  information from DESCRIPTION files (default: \`FALSE\`).

- max_level:

  An integer specifying the maximum depth level for dependency recursion
  (default: 3). Set to a higher value to explore deeper dependency
  layers.

## Value

A nested list representing the dependency tree of the package. If
\`get_license\` is \`TRUE\`, each package in the tree (including the
root package and all dependencies) will have a \`license\` field
containing that package's license extracted from its DESCRIPTION file.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_all_dependencies("ggplot2")
fetch_all_dependencies("ggplot2", get_license = TRUE)
fetch_all_dependencies("ggplot2", max_level = 5)  # Deeper dependency exploration
} # }
```
