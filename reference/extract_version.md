# Extract Package Version from File Path

This function extracts the version number from a package source file
name based on the package name and expected file pattern.

## Usage

``` r
extract_version(path, package_name)
```

## Arguments

- path:

  A character string specifying the file path or URL.

- package_name:

  A character string specifying the name of the package.

## Value

A character string representing the extracted version number, or
\`NULL\` if no match is found.

## Examples

``` r
if (FALSE) { # \dontrun{
link <- "https://bioconductor.org/packages/3.14/bioc/src/contrib/GenomicRanges_1.42.0.tar.gz"
extract_version(link, "GenomicRanges")
} # }
```
