# Assess package

assess package for risk metrics

## Usage

``` r
assess_pkg(pkg_source_path, rcmdcheck_args, covr_timeout = Inf)
```

## Arguments

- pkg_source_path:

  \- source path for install local

- rcmdcheck_args:

  \- arguments for R Cmd check - these come from setup_rcmdcheck_args

- covr_timeout:

  \- setting for covr time out

## Value

list containing results - list containing metrics, covr, tm - trace
matrix, and R CMD check
