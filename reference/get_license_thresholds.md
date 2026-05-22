# Get License Levels from Thresholds

This internal utility function processes a list of license thresholds
and returns a named list of license values grouped by their risk level
(e.g., "high", "medium", "low").

## Usage

``` r
get_license_thresholds(thresholds)
```

## Arguments

- thresholds:

  A list where each element contains a \`level\` (character) and
  \`values\` (list of character vectors).

## Value

A named list with elements \`"high"\`, \`"medium"\`, and \`"low"\`, each
containing a character vector of license names.
