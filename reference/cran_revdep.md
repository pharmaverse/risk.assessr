# Find Reverse Dependencies of a CRAN Package

This function finds the reverse dependencies of a CRAN package, i.e.,
packages that depend on the specified package.

## Usage

``` r
cran_revdep(
  pkg,
  dependencies = c("Depends", "Imports", "Suggests", "LinkingTo"),
  recursive = FALSE,
  ignore = NULL,
  installed = NULL
)
```

## Arguments

- pkg:

  A character string representing the name of the package.

- dependencies:

  A character vector specifying the types of dependencies to consider.
  Default is c("Depends", "Imports", "Suggests", "LinkingTo").

- recursive:

  A logical value indicating whether to find dependencies recursively.
  Default is FALSE.

- ignore:

  A character vector of package names to ignore. Default is NULL.

- installed:

  A matrix of installed packages.

## Value

deps - A sorted character vector of package names that depend on the
specified package.

## Examples

``` r
if (FALSE) { # \dontrun{
cran_revdep("ggplot2")
} # }
```
