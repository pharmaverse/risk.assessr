# Get Total Number of PubMed Articles for a Search Term

This function queries the NCBI E-utilities API to retrieve the total
number of PubMed articles that match a given search term or R package
name.

## Usage

``` r
get_pubmed_count(package_name, api_key = getOption("pubmed.api_key", NULL))
```

## Arguments

- package_name:

  A character string representing the search term (e.g., an R package
  name).

- api_key:

  Optional. A character string with an NCBI API key. If not supplied, it
  will attempt to use the option `getOption("pubmed.api_key")`.

## Value

An integer representing the total number of PubMed articles matching the
search term, or `NA` if the request fails.

## Examples

``` r
if (FALSE) { # \dontrun{
get_pubmed_count("ggplot2")
} # }
```
