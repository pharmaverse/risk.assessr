# set up rcmdcheck arguments

This sets up rcmdcheck arguments

## Usage

``` r
setup_rcmdcheck_args(check_type = "1", build_vignettes)
```

## Arguments

- check_type:

  R CMD check mode: \* \`"1"\` — basic R CMD check (default). \* \`"2"\`
  — frugal mode used by \[get_frugal_metrics()\]: same args as \`"1"\`
  plus \`–no-tests\`, so the test suite is skipped. \* any other value
  (e.g. \`"3"\`) — CRAN-like check (\`–as-cran\`).

- build_vignettes:

  Logical (T/F). Whether or not to build vignettes

## Value

\- list with rcmdcheck arguments

## Details

Some packages need to have build vignettes as a build argument as their
vignettes structure is inst/doc or inst/docs
