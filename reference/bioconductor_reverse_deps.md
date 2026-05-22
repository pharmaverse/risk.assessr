# Find Bioconductor Package Reverse Dependencies

This function returns the reverse dependencies for a given Bioconductor
package.

## Usage

``` r
bioconductor_reverse_deps(
  pkg,
  which = "Imports",
  only.bioc = FALSE,
  version = BiocManager::version(),
  db = NULL,
  biocdb = NULL
)
```

## Arguments

- pkg:

  Character string. The name of the package for which to find reverse
  dependencies.

- which:

  Character vector. The dependency categories to check. One or more of
  `"Depends"`, `"Imports"`, `"LinkingTo"`, `"Suggests"`, or
  `"Enhances"`. Defaults to `"Imports"`.

- only.bioc:

  Logical. If `TRUE` (default), only reverse dependencies that are
  Bioconductor packages are returned.

- version:

  Bioconductor version to use. Defaults to the current version.

- db:

  Optional. A pre-loaded package database to use for lookups.

- biocdb:

  Optional. A pre-loaded Bioconductor package database.

## Value

A named list of reverse dependency package names.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get reverse Imports dependencies as a list:
bioconductor_reverse_deps("limma")

# Get multiple categories:
bioconductor_reverse_deps("limma", which = c("Depends", "Suggests"))
} # }
```
