# Build a Dependency Tree for an R Package

This function constructs a nested list representing the dependency tree
of a specified R package. The recursion stops at the specified maximum
depth level (default: 3) or until a base package is reached.

## Usage

``` r
build_dependency_tree(
  package_name,
  level = 1,
  get_license = FALSE,
  max_level = 3
)
```

## Arguments

- package_name:

  A character string specifying the name of the package.

- level:

  An integer indicating the current recursion depth (default: 1).

- get_license:

  A logical value indicating whether to extract and include license
  information from DESCRIPTION files (default: \`FALSE\`).

- max_level:

  An integer specifying the maximum depth level for dependency recursion
  (default: 3). Set to a higher value to explore deeper dependency
  layers.

## Value

A nested list representing the dependency tree, where base packages are
marked as "base". If \`get_license\` is \`TRUE\`, each package entry in
the tree includes a \`license\` field containing that specific package's
license (extracted from its DESCRIPTION file). Each package's license is
independent - the license of a parent package does not imply the
licenses of its dependencies.

## Examples

``` r
if (FALSE) { # \dontrun{
build_dependency_tree("ggplot2")
build_dependency_tree("ggplot2", get_license = TRUE)
build_dependency_tree("ggplot2", max_level = 5)  # Deeper dependency exploration
} # }
```
