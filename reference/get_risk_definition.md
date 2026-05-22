# Get Risk Definition

Load risk definition config from options, JSON file, or fallback to
bundled file.

## Usage

``` r
get_risk_definition()
```

## Value

A list of risk configuration items.

## Examples

``` r
risk_rule <- get_risk_definition()
#> Using package's default risk definition.
print(risk_rule)
#> [[1]]
#> [[1]]$label
#> [1] "dependency count"
#> 
#> [[1]]$id
#> [1] "dependencies_count"
#> 
#> [[1]]$key
#> [1] "dependencies_count"
#> 
#> [[1]]$thresholds
#> [[1]]$thresholds[[1]]
#> [[1]]$thresholds[[1]]$level
#> [1] "low"
#> 
#> [[1]]$thresholds[[1]]$max
#> [1] 20
#> 
#> 
#> [[1]]$thresholds[[2]]
#> [[1]]$thresholds[[2]]$level
#> [1] "medium"
#> 
#> [[1]]$thresholds[[2]]$max
#> [1] 40
#> 
#> 
#> [[1]]$thresholds[[3]]
#> [[1]]$thresholds[[3]]$level
#> [1] "high"
#> 
#> [[1]]$thresholds[[3]]$max
#> NULL
#> 
#> 
#> 
#> 
#> [[2]]
#> [[2]]$label
#> [1] "version deprecation"
#> 
#> [[2]]$id
#> [1] "version_difference"
#> 
#> [[2]]$key
#> [1] "later_version"
#> 
#> [[2]]$thresholds
#> [[2]]$thresholds[[1]]
#> [[2]]$thresholds[[1]]$level
#> [1] "low"
#> 
#> [[2]]$thresholds[[1]]$max
#> [1] 3
#> 
#> 
#> [[2]]$thresholds[[2]]
#> [[2]]$thresholds[[2]]$level
#> [1] "high"
#> 
#> [[2]]$thresholds[[2]]$max
#> NULL
#> 
#> 
#> 
#> 
#> [[3]]
#> [[3]]$label
#> [1] "code coverage"
#> 
#> [[3]]$id
#> [1] "code_coverage"
#> 
#> [[3]]$key
#> [1] "code_coverage"
#> 
#> [[3]]$thresholds
#> [[3]]$thresholds[[1]]
#> [[3]]$thresholds[[1]]$level
#> [1] "high"
#> 
#> [[3]]$thresholds[[1]]$max
#> [1] 0.6
#> 
#> 
#> [[3]]$thresholds[[2]]
#> [[3]]$thresholds[[2]]$level
#> [1] "medium"
#> 
#> [[3]]$thresholds[[2]]$max
#> [1] 0.8
#> 
#> 
#> [[3]]$thresholds[[3]]
#> [[3]]$thresholds[[3]]$level
#> [1] "low"
#> 
#> [[3]]$thresholds[[3]]$max
#> [1] 1
#> 
#> 
#> 
#> 
#> [[4]]
#> [[4]]$label
#> [1] "popularity"
#> 
#> [[4]]$id
#> [1] "popularity"
#> 
#> [[4]]$key
#> [1] "total_download"
#> 
#> [[4]]$thresholds
#> [[4]]$thresholds[[1]]
#> [[4]]$thresholds[[1]]$level
#> [1] "high"
#> 
#> [[4]]$thresholds[[1]]$max
#> [1] 3500000
#> 
#> 
#> [[4]]$thresholds[[2]]
#> [[4]]$thresholds[[2]]$level
#> [1] "medium"
#> 
#> [[4]]$thresholds[[2]]$max
#> [1] 50000000
#> 
#> 
#> [[4]]$thresholds[[3]]
#> [[4]]$thresholds[[3]]$level
#> [1] "low"
#> 
#> [[4]]$thresholds[[3]]$max
#> NULL
#> 
#> 
#> 
#> 
#> [[5]]
#> [[5]]$label
#> [1] "license"
#> 
#> [[5]]$id
#> [1] "license"
#> 
#> [[5]]$key
#> [1] "license"
#> 
#> [[5]]$default
#> [1] "high"
#> 
#> [[5]]$thresholds
#> [[5]]$thresholds[[1]]
#> [[5]]$thresholds[[1]]$level
#> [1] "high"
#> 
#> [[5]]$thresholds[[1]]$values
#> [[5]]$thresholds[[1]]$values[[1]]
#> [1] "AGPL"
#> 
#> [[5]]$thresholds[[1]]$values[[2]]
#> [1] "SSPL"
#> 
#> [[5]]$thresholds[[1]]$values[[3]]
#> [1] "GNUAFFEROGPL"
#> 
#> [[5]]$thresholds[[1]]$values[[4]]
#> [1] "CECILL"
#> 
#> [[5]]$thresholds[[1]]$values[[5]]
#> [1] "OPENSOFTWARELICENCE"
#> 
#> [[5]]$thresholds[[1]]$values[[6]]
#> [1] "SERVERSIDEPUBLICLICENSE"
#> 
#> [[5]]$thresholds[[1]]$values[[7]]
#> [1] "NOTAVAILABLE"
#> 
#> 
#> 
#> [[5]]$thresholds[[2]]
#> [[5]]$thresholds[[2]]$level
#> [1] "medium"
#> 
#> [[5]]$thresholds[[2]]$values
#> [[5]]$thresholds[[2]]$values[[1]]
#> [1] "GPL"
#> 
#> [[5]]$thresholds[[2]]$values[[2]]
#> [1] "LGPL"
#> 
#> [[5]]$thresholds[[2]]$values[[3]]
#> [1] "ARTISTIC"
#> 
#> 
#> 
#> [[5]]$thresholds[[3]]
#> [[5]]$thresholds[[3]]$level
#> [1] "low"
#> 
#> [[5]]$thresholds[[3]]$values
#> [[5]]$thresholds[[3]]$values[[1]]
#> [1] "MIT"
#> 
#> [[5]]$thresholds[[3]]$values[[2]]
#> [1] "APACHE"
#> 
#> 
#> 
#> 
#> 
#> [[6]]
#> [[6]]$label
#> [1] "reverse dependencies"
#> 
#> [[6]]$id
#> [1] "reverse_dependencies"
#> 
#> [[6]]$key
#> [1] "reverse_dependencies_count"
#> 
#> [[6]]$thresholds
#> [[6]]$thresholds[[1]]
#> [[6]]$thresholds[[1]]$level
#> [1] "high"
#> 
#> [[6]]$thresholds[[1]]$max
#> [1] 5
#> 
#> 
#> [[6]]$thresholds[[2]]
#> [[6]]$thresholds[[2]]$level
#> [1] "medium"
#> 
#> [[6]]$thresholds[[2]]$max
#> [1] 15
#> 
#> 
#> [[6]]$thresholds[[3]]
#> [[6]]$thresholds[[3]]$level
#> [1] "low"
#> 
#> [[6]]$thresholds[[3]]$max
#> NULL
#> 
#> 
#> 
#> 
#> [[7]]
#> [[7]]$label
#> [1] "documentation"
#> 
#> [[7]]$id
#> [1] "documentation"
#> 
#> [[7]]$key
#> [1] "documentation_score"
#> 
#> [[7]]$thresholds
#> [[7]]$thresholds[[1]]
#> [[7]]$thresholds[[1]]$level
#> [1] "high"
#> 
#> [[7]]$thresholds[[1]]$max
#> [1] 3
#> 
#> 
#> [[7]]$thresholds[[2]]
#> [[7]]$thresholds[[2]]$level
#> [1] "medium"
#> 
#> [[7]]$thresholds[[2]]$max
#> [1] 6
#> 
#> 
#> [[7]]$thresholds[[3]]
#> [[7]]$thresholds[[3]]$level
#> [1] "low"
#> 
#> [[7]]$thresholds[[3]]$max
#> NULL
#> 
#> 
#> 
#> 
#> [[8]]
#> [[8]]$label
#> [1] "documentation"
#> 
#> [[8]]$id
#> [1] "documentation"
#> 
#> [[8]]$key
#> [1] "has_ex_docs_score"
#> 
#> [[8]]$thresholds
#> [[8]]$thresholds[[1]]
#> [[8]]$thresholds[[1]]$level
#> [1] "high"
#> 
#> [[8]]$thresholds[[1]]$max
#> [1] 0.6
#> 
#> 
#> [[8]]$thresholds[[2]]
#> [[8]]$thresholds[[2]]$level
#> [1] "medium"
#> 
#> [[8]]$thresholds[[2]]$max
#> [1] 0.8
#> 
#> 
#> [[8]]$thresholds[[3]]
#> [[8]]$thresholds[[3]]$level
#> [1] "low"
#> 
#> [[8]]$thresholds[[3]]$max
#> [1] 1
#> 
#> 
#> 
#> 
#> [[9]]
#> [[9]]$label
#> [1] "R cmd check"
#> 
#> [[9]]$id
#> [1] "cmd-check"
#> 
#> [[9]]$key
#> [1] "cmd_check"
#> 
#> [[9]]$thresholds
#> [[9]]$thresholds[[1]]
#> [[9]]$thresholds[[1]]$level
#> [1] "high"
#> 
#> [[9]]$thresholds[[1]]$max
#> [1] 0
#> 
#> 
#> [[9]]$thresholds[[2]]
#> [[9]]$thresholds[[2]]$level
#> [1] "medium"
#> 
#> [[9]]$thresholds[[2]]$max
#> [1] 0.8
#> 
#> 
#> [[9]]$thresholds[[3]]
#> [[9]]$thresholds[[3]]$level
#> [1] "low"
#> 
#> [[9]]$thresholds[[3]]$max
#> [1] 1
#> 
#> 
#> 
#> 
```
