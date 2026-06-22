# Get popularity metrics from CRAN or Bioconductor package

## CRAN download

``` r

download_cran_df <- get_package_download_cran("admiral", years = 5)
head(download_cran_df)
```

``` r

version_infos <- check_and_fetch_cran_package("admiral")
```

## GitHub commit activity

``` r

repo_info <- get_github_data("tidyverse", "ggplot2")
repo_info
```

``` r

df_commit <- get_commits_since("tidyverse", "ggplot2", years = 1)
head(df_commit)
```

## Bioconductor download

``` r

download_bio_df <- get_package_download_bioconductor("limma")
#> Warning: Failed to open
#> 'https://bioconductor.org/packages/stats/bioc/limma/limma_stats.tab': The
#> requested URL returned error: 404
#> could not fetch download data for package: limma
#> No download data found for package: limma
head(download_bio_df$all_data)
#> NULL
```

``` r

download_bio_df <- get_package_download_bioconductor("DESeq2")
head(download_bio_df$all_data)
```
