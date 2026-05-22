# Fetch Bioconductor Package Information

This function retrieves information about a specific Bioconductor
package for a given Bioconductor version. It fetches the package
details, such as version, source package URL, and archived versions if
available.

## Usage

``` r
fetch_bioconductor_package_info(bioconductor_version, package_name)
```

## Arguments

- bioconductor_version:

  A character string specifying the Bioconductor version (e.g., "3.14").

- package_name:

  A character string specifying the name of the package.

## Value

A list containing package details, including the latest version, package
URL, source package link, and any archived versions if available.
Returns \`FALSE\` if the package does not exist or cannot be retrieved.

## Examples

``` r
if (FALSE) { # \dontrun{
info <- fetch_bioconductor_package_info("3.14", "GenomicRanges")
print(info)
} # }
```
