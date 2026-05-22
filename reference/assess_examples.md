# Assess Rd files for examples (exported functions only)

Scans the package Rd database at \`pkg_source_path\` and reports whether
each \*\*exported function\*\* has examples. Resolution supports shared
topics via roxygen \`@rdname\` (multiple functions documented on the
same Rd page) and multiple \`\alias\` entries.

## Usage

``` r
assess_examples(pkg_name, pkg_source_path)
```

## Arguments

- pkg_name:

  Character scalar; package name (must be loadable so exports can be
  read).

- pkg_source_path:

  Directory path where Rd files can be found by \`tools::Rd_db()\`.

## Value

A list with:

- data:

  A data.frame with columns \`function_name\`, \`documentation_name\`,
  \`documentation_location\`, and \`example\`.

- example_score:

  Numeric; percentage of exported functions with examples.

## Examples

``` r
if (FALSE) { # \dontrun{
  res <- assess_examples("stringr", "<path-to-stringr-source>")
  head(res$data)
  res$example_score
} # }
```
