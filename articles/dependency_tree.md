# Dependency tree

``` r

library(risk.assessr)


tryCatch({
  options(repos = c(CRAN = "http://cran.us.r-project.org"))
}, error = function(e) {
  message("No CRAN available")
})
```

## Dependencies Tree

The `risk.assessr` package provides a set of functions to get
dependencies and visualize dependency trees, allowing users to analyze
package dependencies and identify potential conflicts.

The package also supports license extraction and customizable depth
control for exploring dependency layers.

### Basic Usage

Fetch your primary dependencies from your package:

``` r

download_and_parse_dependencies("stringr")
#> Warning: unable to access index for repository http://cran.us.r-project.org/src/contrib:
#>   cannot open URL 'http://cran.us.r-project.org/src/contrib/PACKAGES'
#> Failed to download or parse stringr - couldn't find package 'stringr'
#> $dependencies
#> [1] package        type           parent_package
#> <0 rows> (or 0-length row.names)
#> 
#> $license
#> [1] NA
```

Create and visualize your dependency tree:

``` r

dep_data <- fetch_all_dependencies("stringr")
#> Building dependency tree for: stringr
#> Dependency tree in progress for stringr package
#> Warning: unable to access index for repository http://cran.us.r-project.org/src/contrib:
#>   cannot open URL 'http://cran.us.r-project.org/src/contrib/PACKAGES'
#> Failed to download or parse stringr - couldn't find package 'stringr'
#> Finished building for stringr
```

``` r

dep_data
#> $stringr
#> $stringr$version
#> [1] "1.6.0"
```

``` r

print_tree(dep_data)
#> └── stringr (v1.6.0)
```

### License Extraction

You can extract license information from package DESCRIPTION files by
setting `get_license = TRUE`.

``` r

dep_data_with_license <- fetch_all_dependencies("stringr", get_license = TRUE)
#> Building dependency tree for: stringr
#> Dependency tree in progress for stringr package
#> Warning: unable to access index for repository http://cran.us.r-project.org/src/contrib:
#>   cannot open URL 'http://cran.us.r-project.org/src/contrib/PACKAGES'
#> Failed to download or parse stringr - couldn't find package 'stringr'
#> Finished building for stringr
```

``` r

print_tree(dep_data_with_license)
#> └── stringr (v1.6.0)
```

By default, the dependency tree explores up to 3 dependency levels deep.
You can control this using the `max_level` parameter:

``` r

# Shallow exploration (only 2 levels)
dep_data_shallow <- fetch_all_dependencies("stringr", get_license = TRUE, max_level = 2)
#> Building dependency tree for: stringr
#> Dependency tree in progress for stringr package
#> Warning: unable to access index for repository http://cran.us.r-project.org/src/contrib:
#>   cannot open URL 'http://cran.us.r-project.org/src/contrib/PACKAGES'
#> Failed to download or parse stringr - couldn't find package 'stringr'
#> Finished building for stringr
print_tree(dep_data_shallow)
#> └── stringr (v1.6.0)
```

``` r

# Deeper exploration (5 levels)
dep_data_deep <- fetch_all_dependencies("stringr", get_license = TRUE, max_level = 5)
#> Building dependency tree for: stringr
#> Dependency tree in progress for stringr package
#> Warning: unable to access index for repository http://cran.us.r-project.org/src/contrib:
#>   cannot open URL 'http://cran.us.r-project.org/src/contrib/PACKAGES'
#> Failed to download or parse stringr - couldn't find package 'stringr'
#> Finished building for stringr
print_tree(dep_data_deep)
#> └── stringr (v1.6.0)
```

### Check for Conflicting Dependency Versions

Detect version conflicts in your dependency tree:

``` r

detect_version_conflicts(dep_data)
#> NULL
```
