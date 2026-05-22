# Extract all aliases from an Rd document

Collects text from \*\*all\*\* \`\alias\` nodes, trimming whitespace and
de-duplicating.

## Usage

``` r
rd_aliases(rd)
```

## Arguments

- rd:

  An Rd object.

## Value

A character vector of aliases (possibly empty).
