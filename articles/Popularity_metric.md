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
head(download_bio_df$all_data)
#>         Date Year Month Nb_of_distinct_IPs Nb_of_downloads Cumulative_downloads
#> 1 2009-01-01 2009   Jan               3341            7053                 7053
#> 2 2009-02-01 2009   Feb               3229            6681                13734
#> 3 2009-03-01 2009   Mar               3753            8021                21755
#> 4 2009-04-01 2009   Apr               4025            8583                30338
#> 5 2009-05-01 2009   May               3476            7524                37862
#> 6 2009-06-01 2009   Jun               3763            7725                45587
#>   Cumulative_IPs
#> 1           3341
#> 2           6570
#> 3          10323
#> 4          14348
#> 5          17824
#> 6          21587
```

``` r
download_bio_df <- get_package_download_bioconductor("DESeq2")
head(download_bio_df$all_data)
```
