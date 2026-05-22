# Get Dependencies

This function extracts the version information of imported and suggested
packages for a given package from the current R session.

## Usage

``` r
get_session_dependencies(deps_list)
```

## Arguments

- deps_list:

  A data frame containing the dependency information of the package
  (provided by calc_dependencies function)

## Value

A list with two elements:

- imports:

  A named list of packages in the "Imports" section along with their
  corresponding versions

- suggests:

  A named list of packages in the "Suggests" section along with their
  corresponding versions

## Examples

``` r
# \donttest{
deps_list <- data.frame(
  package = c("dplyr", "ggplot2", "testthat", "knitr"),
  type = c("Imports", "Imports", "Suggests", "Suggests")
)
get_session_dependencies(deps_list)
#> $imports
#> $imports$dplyr
#> [1] "1.2.1"
#> 
#> $imports$ggplot2
#> [1] "No package version found"
#> 
#> 
#> $suggests
#> $suggests$testthat
#> [1] "3.3.2"
#> 
#> $suggests$knitr
#> [1] "1.51"
#> 
#> 
# }
```
