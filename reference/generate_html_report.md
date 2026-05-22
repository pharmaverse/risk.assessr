# Generate HTML Report for Package Assessment

Generates an HTML report for the package assessment results using
rmarkdown.

## Usage

``` r
generate_html_report(assessment_results, output_dir = NULL)
```

## Arguments

- assessment_results:

  List containing the results from risk_assess_pkg function.

- output_dir:

  Character string indicating the directory where the report will be
  saved.

## Value

Path to the generated HTML report.

## Examples

``` r
if (FALSE) { # \dontrun{
assessment_results <- risk_assess_pkg()
generate_html_report(assessment_results, output_dir = "path/to/save/report")
} # }
```
