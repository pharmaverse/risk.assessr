# risk.assessr metrics

``` r
library(risk.assessr)
```

``` r
here <- risk.assessr::assess_pkg_r_package("here")
```

## Package Risk Assessment Summary

This report presents a risk assessment of the R package: **here**.

### Metadata

``` r
here$results[c("pkg_name", "pkg_version", "sysname", "release", "date_time")]
```

### Documentation Metrics

``` r
here$results[c("license_name", "has_examples", "has_vignettes", "has_news", 
               "has_website", "has_source_control", "export_help", 
               "export_calc", "covr", "check")]
```

### Dependencies

``` r
here$results$dependencies
```

### Test Coverage

``` r
here$covr_list$res_cov$coverage$totalcoverage
```

### CRAN Check Results

``` r
here$check_list$res_check$errors
```

### Popularity Metrics

#### CRAN Downloads

``` r
here$results$download
```

#### GitHub Statistics

``` r
here$results$github_data
```

#### Reverse Dependencies (Extended)

``` r
head(here$results$rev_deps, 10)  
```

### Authorship

``` r
here$results$author
```

### Hosting Information

``` r
here$results$host
```

### Suggested Imports Review

``` r
here$risk_analysis
```

[More info
Here](https://github.com/pharmaverse/risk.assessr/blob/gh-pages/articles/define_custom_risk_rules.html)

### Advanced feature

#### Traceability Matrix

``` r
here$tm_list
```

[More info
Here](https://github.com/pharmaverse/risk.assessr/blob/gh-pages/articles/Traceability_matrix.html)

### Suggested Imports Review

``` r
here$results$suggested_deps
```
