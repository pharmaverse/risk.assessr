# Initialise frugal-mode coverage list

Internal helper that returns a \`covr_list\` placeholder with the exact
nested keys \[generate_html_report()\] reads from \`covr_list\`:

All numeric values are \`0\` so \[generate_trace_matrix_section()\]
short- circuits its \`total_coverage == 0\` branch and renders a
"Traceability matrix unsuccessful" placeholder rather than dereferencing
missing coverage columns.

## Usage

``` r
init_frugal_covr_list()
```

## Value

A list shaped like the output of
\`test.assessr::get_package_coverage()\` but populated with frugal
placeholders that flow safely through every accessor in
\[generate_html_report()\] and \[write_summary_report()\].
