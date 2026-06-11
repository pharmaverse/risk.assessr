# Normalize an R source path for coverage join keys

Strips directory/extension and ignores hyphen, underscore, and case
differences so `man/geom_alluvium.Rd` (`R/geom_alluvium.R`) matches covr
keys like `R/geom-alluvium.r`.

## Usage

``` r
normalize_code_script_key(path)
```

## Arguments

- path:

  Character scalar, e.g. `"R/geom-alluvium.r"`.

## Value

Normalized basename without separators, or `NA_character_`.
