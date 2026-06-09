# Get pubmed data

## Introduction

This vignette demonstrates how to retrieve citation data from PubMed
using:

- [`get_pubmed_count()`](https://pharmaverse.github.io/risk.assessr/reference/get_pubmed_count.md)
  — to retrieve the total count of articles matching a term.
- [`get_pubmed_by_year()`](https://pharmaverse.github.io/risk.assessr/reference/get_pubmed_by_year.md)
  — to get article counts by publication year.

These functions are part of the `risk.assessr` package.

DISCLAIMER: This feature only works if you choose a good R package name.

------------------------------------------------------------------------

## Setting Your PubMed API Key

To increase request limits and improve stability, you can use an NCBI
API key.

To add a PubMed API key (token), please follow the steps
[Here](https://support.nlm.nih.gov/kbArticle/?pn=KA-05317)

``` r

# Replace with your actual API key
options(pubmed.api_key = "your_actual_ncbi_api_key")
```

------------------------------------------------------------------------

## Load Required Libraries

``` r

library(risk.assessr)
library(ggplot2)

package_name <- "limma"
```

------------------------------------------------------------------------

## Total Number of Articles Matching a Term

``` r

pubmed_count <- get_pubmed_count(package_name)
pubmed_count
```

------------------------------------------------------------------------

## Number of Articles by Year

``` r

citation_data <- get_pubmed_by_year(package_name, years_back = 20)
citation_data
```

------------------------------------------------------------------------

## Plotting the Article Trend Over Time
