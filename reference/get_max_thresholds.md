# Extract Maximum Thresholds for Code Coverage Levels

This internal function retrieves the \`max\` values for
\`"high"\`,\`"medium"\`, and \`"low"\` levels from a list of code
coverage thresholds.

## Usage

``` r
get_max_thresholds(thresholds)
```

## Arguments

- thresholds:

  A list of threshold objects, each containing a \`level\` and \`max\`
  field.

## Value

A list with three elements:

- high_max:

  The maximum threshold value for the \`"high"\` level.

- medium_max:

  The maximum threshold value for the \`"medium"\` level.

- medium_max:

  The maximum threshold value for the \`"low"\` level.
