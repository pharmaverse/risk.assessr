# Get Annual PubMed Article Counts for a Search Term

This function queries the NCBI E-utilities API to retrieve the number of
PubMed articles published each year over a specified number of past
years for a given search term or package name.

## Usage

``` r
get_pubmed_by_year(
  package_name,
  years_back = 10,
  api_key = getOption("pubmed.api_key", NULL)
)
```

## Arguments

- package_name:

  A character string representing the search term (e.g., an R package
  name).

- years_back:

  An integer specifying how many years back to query. Defaults to 10.

- api_key:

  Optional. A character string with an NCBI API key. If not supplied, it
  will attempt to use the option `getOption("pubmed.api_key")`.

## Value

A data frame with two columns:

- Year:

  The publication year (integer).

- Count:

  The number of articles published in that year (integer).

Returns an empty data frame if no valid data is retrieved.

## Examples

``` r
if (FALSE) { # \dontrun{
get_pubmed_by_year("ggplot2", years_back = 5)
} # }
```
