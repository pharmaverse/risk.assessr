# Get the first Rd section by tag

Depth-first search returning the first node whose \`Rd_tag\` equals
\`paste0("\\", section)\`.

## Usage

``` r
get_rd_section(rd, section)
```

## Arguments

- rd:

  An Rd object (a nested list with "Rd_tag" attributes on nodes).

- section:

  Section name without leading backslash (e.g., "alias", "examples").

## Value

The first matching Rd node or \`NULL\` if not found.
