# Parse HTML Content for Package Versions

This function extracts version information from an HTML page listing
available versions of a Bioconductor package.

This function extracts version information from the HTML content of a
CRAN archive page.

## Usage

``` r
parse_html_version(html_content, package_name)

parse_html_version(html_content, package_name)
```

## Arguments

- html_content:

  A character string containing the HTML content of a CRAN package
  archive page.

- package_name:

  A character string specifying the name of the package to extract
  version information for.

## Value

A list of lists containing package details such as package name,
version, link, date, and size. Returns an empty list if no versions are
found.

A list of lists, where each sublist contains: - \`package_name\`:
package name. - \`package_version\`: package version. - \`link\`: link
to the package tarball. - \`date\`: The date associated with the package
version. - \`size\`: The size of the package tarball.

## Examples

``` r
if (FALSE) { # \dontrun{
parse_html_version(html_content, "GenomicRanges")
} # }
if (FALSE) { # \dontrun{
html_content <- parse_package_info("dplyr")
parse_html_version(html_content, "dplyr")
} # }
```
