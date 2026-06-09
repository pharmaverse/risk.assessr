# Parse exported names from a package's NAMESPACE on disk.

Used as a fallback when the package is not loaded as a namespace (for
example when \`R CMD INSTALL\` failed because the package has no R/
folder on stricter R versions).

## Usage

``` r
get_exports_from_source(pkg_source_path)
```

## Arguments

- pkg_source_path:

  Path to the unpacked package source.

## Value

Character vector of exported names (possibly empty).
