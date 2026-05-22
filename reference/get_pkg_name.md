# get package name for display

get package name for display

## Usage

``` r
get_pkg_name(input_string)
```

## Arguments

- input_string:

  \- string containing package name

## Value

pkg_disp - package name for display

## Examples

``` r
# \donttest{
pkg_source_path <- "/home/user/R/test.package.0001_0.1.0.tar.gz"
pkg_disp_1 <- get_pkg_name(pkg_source_path)
print(pkg_disp_1)
#> [1] "test.package.0001"

pkg <- "TxDb.Dmelanogaster.UCSC.dm3.ensGene_3.2.2.tar.gz"
pkg_disp_2 <- get_pkg_name(pkg)
print(pkg_disp_2)
#> [1] "TxDb.Dmelanogaster.UCSC.dm3.ensGene"
# }
```
