# Detect Version Conflicts from dependency tree

This function identifies duplicate version packages and reports
conflicts.

## Usage

``` r
detect_version_conflicts(pkg_list)
```

## Arguments

- pkg_list:

  A nested list structure from fetch_all_dependencies function

## Value

A list of strings describing package version conflicts such as "Conflict
in package cli: versions found - 3.6.2, 3.6.1" \`NULL\` if no conflicts
are found.

## Examples

``` r
pkg_list <- list(
  ggplot2 = list(
    version = "3.5.1",
    cli = list(version = "3.6.2"),
    gtable = list(
      version = "0.3.4",
      cli = list(version = "3.6.1")
    )
  )
)
detect_version_conflicts(pkg_list)
#> [[1]]
#> [1] "Conflict in package cli: versions found - 3.6.2, 3.6.1"
#> 
```
