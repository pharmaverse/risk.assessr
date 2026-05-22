# Check if a Package is a Base or Recommended R Package

This function determines whether a given package is a base or
recommended package using CRAN metadata.

## Usage

``` r
is_base(pkg)
```

## Arguments

- pkg:

  A character string representing the name of the package.

## Value

A logical value: \`TRUE\` if the package is a base or recommended
package, \`FALSE\` otherwise.

## Examples

``` r
if (FALSE) { # \dontrun{
is_base("stats")     # TRUE
is_base("ggplot2")   # FALSE
} # }
```
