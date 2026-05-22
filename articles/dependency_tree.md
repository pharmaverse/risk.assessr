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
#> $dependencies
#>                package    type parent_package
#> 1                  cli Imports        stringr
#> 2      glue (>= 1.6.1) Imports        stringr
#> 3 lifecycle (>= 1.0.3) Imports        stringr
#> 4             magrittr Imports        stringr
#> 5    rlang\n(>= 1.0.0) Imports        stringr
#> 6   stringi (>= 1.5.3) Imports        stringr
#> 7     vctrs (>= 0.4.0) Imports        stringr
#> 
#> $license
#> [1] NA
```

Create and visualize your dependency tree:

``` r
dep_data <- fetch_all_dependencies("stringr")
#> Building dependency tree for: stringr
#> Dependency tree in progress for stringr package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for glue package
#> Failed to download or parse glue - cannot open URL 'http://cran.us.r-project.org/src/contrib/glue_1.8.1.tar.gz'
#> Finished building for glue
#> Dependency tree in progress for lifecycle package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Finished building for lifecycle
#> Dependency tree in progress for magrittr package
#> Finished building for magrittr
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Dependency tree in progress for stringi package
#> Finished building for stringi
#> Dependency tree in progress for vctrs package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for glue package
#> Finished building for glue
#> Dependency tree in progress for lifecycle package
#> Dependency tree in progress for cli package
#> Dependency tree in progress for rlang package
#> Finished building for lifecycle
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Finished building for vctrs
#> Finished building for stringr
```

``` r
dep_data
#> $stringr
#> $stringr$version
#> [1] "1.5.2"
#> 
#> $stringr$cli
#> $stringr$cli$version
#> [1] "3.6.5"
#> 
#> $stringr$cli$utils
#> [1] "base"
#> 
#> 
#> $stringr$glue
#> $stringr$glue$version
#> [1] "1.8.1"
#> 
#> 
#> $stringr$lifecycle
#> $stringr$lifecycle$version
#> [1] "1.0.5"
#> 
#> $stringr$lifecycle$cli
#> $stringr$lifecycle$cli$version
#> [1] "3.6.5"
#> 
#> $stringr$lifecycle$cli$utils
#> [1] "base"
#> 
#> 
#> $stringr$lifecycle$rlang
#> $stringr$lifecycle$rlang$version
#> [1] "1.1.7"
#> 
#> $stringr$lifecycle$rlang$utils
#> [1] "base"
#> 
#> 
#> 
#> $stringr$magrittr
#> $stringr$magrittr$version
#> [1] "2.0.4"
#> 
#> 
#> $stringr$rlang
#> $stringr$rlang$version
#> [1] "1.1.7"
#> 
#> $stringr$rlang$utils
#> [1] "base"
#> 
#> 
#> $stringr$stringi
#> $stringr$stringi$version
#> [1] "1.8.7"
#> 
#> $stringr$stringi$tools
#> [1] "base"
#> 
#> $stringr$stringi$utils
#> [1] "base"
#> 
#> $stringr$stringi$stats
#> [1] "base"
#> 
#> 
#> $stringr$vctrs
#> $stringr$vctrs$version
#> [1] "0.7.3"
#> 
#> $stringr$vctrs$cli
#> $stringr$vctrs$cli$version
#> [1] "3.6.5"
#> 
#> $stringr$vctrs$cli$utils
#> [1] "base"
#> 
#> 
#> $stringr$vctrs$glue
#> $stringr$vctrs$glue$version
#> [1] "1.8.1"
#> 
#> $stringr$vctrs$glue$methods
#> [1] "base"
#> 
#> 
#> $stringr$vctrs$lifecycle
#> $stringr$vctrs$lifecycle$version
#> [1] "1.0.5"
#> 
#> 
#> $stringr$vctrs$rlang
#> $stringr$vctrs$rlang$version
#> [1] "1.1.7"
#> 
#> $stringr$vctrs$rlang$utils
#> [1] "base"
```

``` r
print_tree(dep_data)
#> └── stringr (v1.5.2)
#>     ├── cli (v3.6.5)
#>     │   └── utils (base)
#>     ├── glue (v1.8.1)
#>     ├── lifecycle (v1.0.5)
#>     │   ├── cli (v3.6.5)
#>     │   │   └── utils (base)
#>     │   └── rlang (v1.1.7)
#>     │       └── utils (base)
#>     ├── magrittr (v2.0.4)
#>     ├── rlang (v1.1.7)
#>     │   └── utils (base)
#>     ├── stringi (v1.8.7)
#>     │   ├── tools (base)
#>     │   ├── utils (base)
#>     │   └── stats (base)
#>     └── vctrs (v0.7.3)
#>         ├── cli (v3.6.5)
#>         │   └── utils (base)
#>         ├── glue (v1.8.1)
#>         │   └── methods (base)
#>         ├── lifecycle (v1.0.5)
#>         └── rlang (v1.1.7)
#>             └── utils (base)
```

### License Extraction

You can extract license information from package DESCRIPTION files by
setting `get_license = TRUE`.

``` r
dep_data_with_license <- fetch_all_dependencies("stringr", get_license = TRUE)
#> Building dependency tree for: stringr
#> Dependency tree in progress for stringr package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for glue package
#> Finished building for glue
#> Dependency tree in progress for lifecycle package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Finished building for lifecycle
#> Dependency tree in progress for magrittr package
#> Finished building for magrittr
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Dependency tree in progress for stringi package
#> Finished building for stringi
#> Dependency tree in progress for vctrs package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for glue package
#> Finished building for glue
#> Dependency tree in progress for lifecycle package
#> Dependency tree in progress for cli package
#> Dependency tree in progress for rlang package
#> Finished building for lifecycle
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Finished building for vctrs
#> Finished building for stringr
```

``` r
print_tree(dep_data_with_license)
#> └── stringr (v1.5.2) MIT + file LICENSE license
#>     ├── cli (v3.6.5) MIT + file LICENSE
#>     │   └── utils (base)
#>     ├── glue (v1.8.1) MIT + file LICENSE
#>     │   └── methods (base)
#>     ├── lifecycle (v1.0.5) MIT + file LICENSE
#>     │   ├── cli (v3.6.5) MIT + file LICENSE
#>     │   │   └── utils (base)
#>     │   └── rlang (v1.1.7) MIT + file LICENSE
#>     │       └── utils (base)
#>     ├── magrittr (v2.0.4) MIT + file LICENSE
#>     ├── rlang (v1.1.7) MIT + file LICENSE
#>     │   └── utils (base)
#>     ├── stringi (v1.8.7) file LICENSE
#>     │   ├── tools (base)
#>     │   ├── utils (base)
#>     │   └── stats (base)
#>     └── vctrs (v0.7.3) MIT + file LICENSE
#>         ├── cli (v3.6.5) MIT + file LICENSE
#>         │   └── utils (base)
#>         ├── glue (v1.8.1) MIT + file LICENSE
#>         │   └── methods (base)
#>         ├── lifecycle (v1.0.5) MIT + file LICENSE
#>         └── rlang (v1.1.7) MIT + file LICENSE
#>             └── utils (base)
```

By default, the dependency tree explores up to 3 dependency levels deep.
You can control this using the `max_level` parameter:

``` r
# Shallow exploration (only 2 levels)
dep_data_shallow <- fetch_all_dependencies("stringr", get_license = TRUE, max_level = 2)
#> Building dependency tree for: stringr
#> Dependency tree in progress for stringr package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for glue package
#> Finished building for glue
#> Dependency tree in progress for lifecycle package
#> Dependency tree in progress for cli package
#> Dependency tree in progress for rlang package
#> Finished building for lifecycle
#> Dependency tree in progress for magrittr package
#> Finished building for magrittr
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Dependency tree in progress for stringi package
#> Finished building for stringi
#> Dependency tree in progress for vctrs package
#> Dependency tree in progress for cli package
#> Dependency tree in progress for glue package
#> Dependency tree in progress for lifecycle package
#> Dependency tree in progress for rlang package
#> Finished building for vctrs
#> Finished building for stringr
print_tree(dep_data_shallow)
#> └── stringr (v1.5.2) MIT + file LICENSE license
#>     ├── cli (v3.6.5) MIT + file LICENSE
#>     │   └── utils (base)
#>     ├── glue (v1.8.1) MIT + file LICENSE
#>     │   └── methods (base)
#>     ├── lifecycle (v1.0.5) MIT + file LICENSE
#>     ├── magrittr (v2.0.4) MIT + file LICENSE
#>     ├── rlang (v1.1.7) MIT + file LICENSE
#>     │   └── utils (base)
#>     ├── stringi (v1.8.7) file LICENSE
#>     │   ├── tools (base)
#>     │   ├── utils (base)
#>     │   └── stats (base)
#>     └── vctrs (v0.7.3) MIT + file LICENSE
```

``` r
# Deeper exploration (5 levels)
dep_data_deep <- fetch_all_dependencies("stringr", get_license = TRUE, max_level = 5)
#> Building dependency tree for: stringr
#> Dependency tree in progress for stringr package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for glue package
#> Finished building for glue
#> Dependency tree in progress for lifecycle package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Finished building for lifecycle
#> Dependency tree in progress for magrittr package
#> Finished building for magrittr
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Dependency tree in progress for stringi package
#> Finished building for stringi
#> Dependency tree in progress for vctrs package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for glue package
#> Finished building for glue
#> Dependency tree in progress for lifecycle package
#> Dependency tree in progress for cli package
#> Finished building for cli
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Finished building for lifecycle
#> Dependency tree in progress for rlang package
#> Finished building for rlang
#> Finished building for vctrs
#> Finished building for stringr
print_tree(dep_data_deep)
#> └── stringr (v1.5.2) MIT + file LICENSE license
#>     ├── cli (v3.6.5) MIT + file LICENSE
#>     │   └── utils (base)
#>     ├── glue (v1.8.1) MIT + file LICENSE
#>     │   └── methods (base)
#>     ├── lifecycle (v1.0.5) MIT + file LICENSE
#>     │   ├── cli (v3.6.5) MIT + file LICENSE
#>     │   │   └── utils (base)
#>     │   └── rlang (v1.1.7) MIT + file LICENSE
#>     │       └── utils (base)
#>     ├── magrittr (v2.0.4) MIT + file LICENSE
#>     ├── rlang (v1.1.7) MIT + file LICENSE
#>     │   └── utils (base)
#>     ├── stringi (v1.8.7) file LICENSE
#>     │   ├── tools (base)
#>     │   ├── utils (base)
#>     │   └── stats (base)
#>     └── vctrs (v0.7.3) MIT + file LICENSE
#>         ├── cli (v3.6.5) MIT + file LICENSE
#>         │   └── utils (base)
#>         ├── glue (v1.8.1) MIT + file LICENSE
#>         │   └── methods (base)
#>         ├── lifecycle (v1.0.5) MIT + file LICENSE
#>         │   ├── cli (v3.6.5) MIT + file LICENSE
#>         │   │   └── utils (base)
#>         │   └── rlang (v1.1.7) MIT + file LICENSE
#>         │       └── utils (base)
#>         └── rlang (v1.1.7) MIT + file LICENSE
#>             └── utils (base)
```

### Check for Conflicting Dependency Versions

Detect version conflicts in your dependency tree:

``` r
detect_version_conflicts(dep_data)
#> NULL
```
