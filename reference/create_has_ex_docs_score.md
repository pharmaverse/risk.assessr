# Combine example/docs scores into a single metric (sum).

Combine example/docs scores into a single metric (sum).

## Usage

``` r
create_has_ex_docs_score(example_score, has_docs_score)
```

## Arguments

- example_score:

  Numeric (scalar or vector) in \[0, 1\] or NA.

- has_docs_score:

  Numeric (scalar or vector) in \[0, 1\] or NA.

## Value

Numeric vector: example_score + has_docs_score in \[0, 2\], with NA
where both inputs are NA at that position.
