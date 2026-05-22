# Clean and normalize license names

Splits a license string on commas, plus signs, or pipes, trims
whitespace, removes trailing noise like "file LICENSE", and normalizes
each part to uppercase letters only.

## Usage

``` r
clean_license(x)
```

## Arguments

- x:

  A character string containing license information.

## Value

A character vector of normalized license names.
