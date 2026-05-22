# Modify the DESCRIPTION File in a R Package Tarball

This function recreate a \`.tar.gz\` R package file after modifying its
\`DESCRIPTION\` file by appending Config/build/clean-inst-doc: false
parameter.

## Usage

``` r
modify_description_file(tar_file)
```

## Arguments

- tar_file:

  A string representing the path to the \`.tar.gz\` file that contains
  the R package.

## Value

A string containing the path to the newly created modified \`.tar.gz\`
file, or the original \`tar_file\` path unchanged if modification was
unnecessary or failed.

## Examples

``` r
if (FALSE) { # \dontrun{
  modified_tar <- modify_description_file("path/to/mypackage.tar.gz")
} # }
```
