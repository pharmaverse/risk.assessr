# Determine Packages that Depend on Given Packages

This function identifies packages that depend on the specified packages,
considering various types of dependencies (e.g., strong, most, all).

## Usage

``` r
dependsOnPkgs(
  pkgs,
  dependencies = "most",
  recursive = TRUE,
  lib.loc = NULL,
  installed = NULL
)
```

## Arguments

- pkgs:

  A character vector of package names to check dependencies for.

- dependencies:

  A character string specifying the types of dependencies to consider.
  Can be "strong", "most", "all", or a custom vector of dependency
  types.

- recursive:

  A logical value indicating whether to recursively check dependencies.

- lib.loc:

  A character vector of library locations to search for installed
  packages.

- installed:

  A matrix of installed packages, obtained from cran_packages function.
  .

## Value

A character vector of package names that depend on the specified
packages.

## Examples

``` r
if (FALSE) { # \dontrun{
installed <- cran_packages()
dependsOnPkgs("here", installed = installed)
} # }
```
