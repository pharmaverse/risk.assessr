# Reclassify Forbidden Notes as Errors in rcmdcheck Results

This internal helper function scans the \`notes\` field of an
\`rcmdcheck\` result object for specific patterns that indicate more
serious issues. If any of these patterns are found, the corresponding
notes are reclassified as errors by moving them from the \`notes\` field
to the \`errors\` field.

## Usage

``` r
check_forbidden_notes(res_check, pkg_name)
```

## Arguments

- res_check:

  A list representing the result of an \`rcmdcheck\` run. It should
  contain at least the elements \`notes\`, \`warnings\`, and \`errors\`,
  each being a character vector.

- pkg_name:

  name of the package

## Value

A modified version of \`res_check\` where certain notes matching
forbidden patterns are moved to the \`errors\` field.
