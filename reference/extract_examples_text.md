# Extract examples text from an Rd document

Supports both \`\examples\` and \`\example\` sections. If multiple
sections exist, their contents are concatenated with blank lines.

## Usage

``` r
extract_examples_text(rd_doc)
```

## Arguments

- rd_doc:

  An Rd document.

## Value

Character scalar of combined examples text, or \`NULL\` if
none/non‑informative.
