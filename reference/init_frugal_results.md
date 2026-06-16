# Initialise frugal-mode result placeholders

Internal helper used by \[get_frugal_metrics()\] to fill the slots of a
\`results\` list that the frugal pipeline does \*\*not\*\* compute (test
coverage, remote metadata) with safe placeholders. The shape mirrors
what \[assess_pkg()\] produces so \[generate_html_report()\] and
\[write_summary_report()\] keep working without special-casing frugal
output.

Existing values are preserved — a slot is only overwritten when it is
missing or empty.

## Usage

``` r
init_frugal_results(results)
```

## Arguments

- results:

  A \`results\` list (typically produced by \[create_empty_results()\]
  and partially populated by the frugal pipeline).

## Value

The \`results\` list with the placeholders described above.
