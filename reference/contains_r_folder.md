# Check for Vignette Folder and .Rmd Files in a .tar File

This function checks if a given .tar file contains a 'vignettes' folder
and if there is at least one .Rmd file within that folder. If both
'vignettes' and 'inst/doc' folders exist, the function will return
`FALSE`.

## Usage

``` r
contains_r_folder(package_dir)
```

## Arguments

- package_dir:

  A character string specifying the path to the package to be checked.

## Value

A logical value: `TRUE` if the 'R' folder exists, `FALSE` otherwise.

## Details

The function checks if the specified folder exists. If 'R' folder does
not exist, the function returns `FALSE`. If the R folder exists, the
function returns `TRUE`.
