# Get available versions

``` r

library(risk.assessr)
```

## Get package version from CRAN

**risk.assessr** can fetch the version available for an R package along
with the release date.

``` r

result_cran <- check_and_fetch_cran_package("admiral", "1.0.0")
```

``` r

result_cran$package_url
```

``` r

result_cran$last_version
```

``` r

head(result_cran$all_versions, n = 2) 
```

## Get package version from Bioconductor

**risk.assessr** can fetch the version available for an R package stored
on [bioconductor](https://www.bioconductor.org/)

``` r

html_content <- fetch_bioconductor_releases()
release_data <- parse_bioconductor_releases(html_content)
```

The function below will retrieve the versions of bioconductor package
corresponding to bioconductor version. In the example below, we find the
versions **2.20.0** of **flowCore** package for the bioconductor version
**3.21**

Note: This function is not able to find all the archived versions for a
Bioconductor package

``` r

fetch_bioconductor_package_info("3.21", "flowCore")
```

This function below gets the **flowCore** package version for all
version of Bioconductor

``` r

html_content <- fetch_bioconductor_releases()
release_data <- parse_bioconductor_releases(html_content)
result_bio <- get_bioconductor_package_url("flowCore", "2.18.0", release_data)
```

``` r

head(result_bio$all_versions, n=2)
```

``` r

result_bio$last_version
```

``` r

result_bio$bioconductor_version_package
```

``` r

result_bio$url
```

``` r

result_bio$archived
```
