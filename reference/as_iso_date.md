# Convert input to ISO 8601 date (YYYY-MM-DD)

Formats inputs as ISO 8601 calendar dates (\`"YYYY-MM-DD"\`).

## Usage

``` r
as_iso_date(x)
```

## Arguments

- x:

  A vector coercible to \`Date\` (e.g., character, \`Date\`, or
  \`POSIXct\`). If \`NULL\`, the function returns \`NULL\`.

## Value

A character vector the same length as \`x\` (or \`NULL\` if \`x\` is
\`NULL\`) with dates formatted as \`"YYYY-MM-DD"\`. Unparseable elements
or \`NA\`s become \`NA_character\_\`.

## Details

Coercion uses \[base::as.Date()\], so time-of-day and timezone
information are dropped. For \`POSIXct\` inputs, the date is computed by
\`as.Date.POSIXct\` (which uses \`tz = "UTC"\` by default). Be aware
that ambiguous character dates (e.g., \`"01/02/2024"\`) depend on your R
locale/format unless you specify a format before calling this function.
