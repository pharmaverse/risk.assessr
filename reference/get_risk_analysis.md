# Get Risk Analysis

Compute risk levels for nested package metadata or flat risk metric
input.

## Usage

``` r
get_risk_analysis(data)
```

## Arguments

- data:

  The nested package metadata, as returned by
  [`assess_pkg()`](https://pharmaverse.github.io/risk.assessr/reference/assess_pkg.md),
  or a flat list of risk metric values.

## Value

A named list of computed risk levels.

## Examples

``` r
# Minimal mock input for demonstration
mock_data <- list(
  dependencies_count = 5,
  later_version = 2,
  code_coverage = 0.75,
  total_download = 150000,
  license = "MIT",
  reverse_dependencies_count = 10,
  documentation_score = 2,
  has_examples = list(
    data = data.frame(
      function_name          = "somefunction",
      documentation_name     = "No documentation found",
      documentation_location = 0,
      example                = "no Rd file",
      stringsAsFactors       = FALSE
    ),
    example_score = 0.20   
  ),
  has_docs = list(
    data = data.frame(
      function_name    = "somefunction",
      stringsAsFactors = FALSE
    ),
    has_docs_score = 0.30  
  ),
  cmd_check = 0
)

get_risk_analysis(mock_data)
#> Using package's default risk definition.
#> $dependencies_count
#> [1] "low"
#> 
#> $later_version
#> [1] "low"
#> 
#> $code_coverage
#> [1] "medium"
#> 
#> $total_download
#> [1] "high"
#> 
#> $license
#> [1] "low"
#> 
#> $reverse_dependencies_count
#> [1] "medium"
#> 
#> $documentation_score
#> [1] "high"
#> 
#> $has_ex_docs_score
#> [1] "unknown"
#> 
#> $cmd_check
#> [1] "high"
#> 
#> $has_bug_reports_url_risk
#> [1] "high"
#> 
#> $has_source_control_risk
#> [1] "high"
#> 
```
