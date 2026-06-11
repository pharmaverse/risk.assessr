# Build a lookup from normalized R script keys to actual `R/` paths

Build a lookup from normalized R script keys to actual `R/` paths

## Usage

``` r
build_r_script_lookup(pkg_source_path)
```

## Arguments

- pkg_source_path:

  Path to an unpacked package source tree.

## Value

Named character vector: normalized key -\> `"R/<file>"`.
