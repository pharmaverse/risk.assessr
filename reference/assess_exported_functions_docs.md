# Assess documentation coverage for exported functions

Scans the package Rd database at \`pkg_source_path\` and resolves
exported functions to their Rd pages to determine whether documentation
exists. Resolution supports shared topics and multiple \`\alias\`
entries, and the returned data includes only \`function_name\`,
\`documentation_name\`, and \`documentation_location\`, together with a
score representing the fraction of exported functions that have any Rd
documentation.

## Usage

``` r
assess_exported_functions_docs(pkg_name, pkg_source_path)
```

## Arguments

- pkg_name:

  Character scalar; package name (must be loadable).

- pkg_source_path:

  Directory path where Rd files can be found by \`tools::Rd_db()\`.

## Value

A list with:

- data:

  A \`data.frame\` with columns \`function_name\`,
  \`documentation_name\`, and \`documentation_location\`.

- has_docs_score:

  Numeric in \\0, 1\\; fraction of exported functions that have an Rd
  page.
