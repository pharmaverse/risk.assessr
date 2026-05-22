# Flatten example nodes to a text block

Recursively collects example text from nodes that carry R code or text,
unwrapping containers such as \`\dontrun\`, \`\donttest\`, and
\`\dontshow\`.

## Usage

``` r
rd_examples_to_text(node)
```

## Arguments

- node:

  An Rd node.

## Value

Character scalar containing example text or \`""\` if none.
