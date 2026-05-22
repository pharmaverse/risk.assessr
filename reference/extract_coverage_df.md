# Build a file-coverage data frame from a single res_cov object

Build a file-coverage data frame from a single res_cov object

## Usage

``` r
extract_coverage_df(res_cov, pkg_name)
```

## Arguments

- res_cov:

  The `res_cov` list (containing `coverage`, `errors`, `notes`).

- pkg_name:

  Name of the package (used to strip temp paths from file names).
