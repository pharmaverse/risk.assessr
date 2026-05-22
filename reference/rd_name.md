# Extract the topic name from an Rd document

Returns the \`\name\` (roxygen \`@rdname\`) of the Rd document.

## Usage

``` r
rd_name(rd)
```

## Arguments

- rd:

  An Rd object.

## Value

A length-1 character scalar (topic name) or \`NA_character\_\` if
missing.
