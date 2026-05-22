# Check for Vignette Folder and .Rmd Files in a .tar File

This function checks if a given .tar file contains a 'vignettes' folder
and if there is at least one .Rmd file within that folder. If both
'vignettes' and 'inst/doc' folders exist, the function will return
`FALSE`.

## Usage

``` r
contains_vignette_folder(tar_file)
```

## Arguments

- tar_file:

  A character string specifying the path to the .tar file to be checked.

## Value

A logical value: `TRUE` if the 'vignettes' folder exists and contains at
least one .Rmd file, and neither 'vignettes' nor 'inst/doc' folders are
present, `FALSE` otherwise.

## Details

The function checks if the specified file exists and has a valid .tar
extension using [`utils::untar`](https://rdrr.io/r/utils/untar.html). If
the file is empty or any error occurs during the extraction, the
function stops and returns an error message. If both 'vignettes' and
'inst/doc' folders exist, the function returns `FALSE`. If the
'vignettes' folder exists and contains at least one .Rmd file, the
function returns `TRUE`. Otherwise, it returns `FALSE`.
