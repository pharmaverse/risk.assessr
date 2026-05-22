# Parse Bioconductor Release Announcements

This function extracts Bioconductor release details such as version
number, release date, number of software packages, and required R
version from the release announcements HTML page.

## Usage

``` r
parse_bioconductor_releases(html_content)
```

## Arguments

- html_content:

  The parsed HTML document from \`fetch_bioconductor_releases\`.

## Value

A list of lists containing Bioconductor release details: release
version, date, number of software packages, and corresponding R version.

## Examples

``` r
if (FALSE) { # \dontrun{
html_content <- fetch_bioconductor_releases()
release_data <- parse_bioconductor_releases(html_content)
print(release_data)
} # }
```
