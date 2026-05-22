# Creates information on package installation

Creates information on package installation

## Usage

``` r
set_up_pkg(package_path, check_type = "1")
```

## Arguments

- package_path:

  Path to the package tarball (.tar.gz).

- check_type:

  Type of R CMD check: "1" for basic, "2" for CRAN-like.

## Value

list with local package install

## Examples

``` r
if (FALSE) { # \dontrun{
set_up_pkg("path/to/tarball")
} # }
```
