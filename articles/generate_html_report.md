# Generate html risk report

``` r
library(risk.assessr)
```

``` r
result <- risk.assessr::assess_pkg_r_package("ggplot2")
generate_html_report(result)
```

## Generate the risk report in a specific path

``` r
generate_html_report(result, output_dir= system.file("examples/", package = "risk.assessr"))
```

## See the `ggplot2` package risk report in the web browser

### The report includes different types of traceability matrices:

- All Exported Functions
- High Risk Functions
- Medium Risk Functions
- Low Risk Functions
- Defunct Functions
- Imported Functions
- Re-exported Functions
- Experimental Functions
