# set up rcmdcheck arguments

This sets up rcmdcheck arguments

## Usage

``` r
setup_rcmdcheck_args(check_type = "1", build_vignettes)
```

## Arguments

- check_type:

  basic R CMD check type - "1" CRAN R CMD check_type - "2"

- build_vignettes:

  Logical (T/F). Whether or not to build vignettes

## Value

\- list with rcmdcheck arguments

## Details

Some packages need to have build vignettes as a build argument as their
vignettes structure is inst/doc or inst/docs
