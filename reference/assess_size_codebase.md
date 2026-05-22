# assess codebase size

Scores packages based on its codebase size, as determined by number of
lines of code.

## Usage

``` r
assess_size_codebase(pkg_source_path)
```

## Arguments

- pkg_source_path:

  \- source path for install local

## Value

\- size_codebase - numeric value between `0` (for small codebase) and
`1` (for large codebase)
