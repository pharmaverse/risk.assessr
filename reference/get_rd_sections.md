# Get all Rd sections by tag

Recursively collects all nodes whose \`Rd_tag\` matches a given section
name, e.g., "alias", "examples", "example", "name".

## Usage

``` r
get_rd_sections(rd, section)
```

## Arguments

- rd:

  An Rd object (a nested list with "Rd_tag" attributes on nodes).

- section:

  Section name without leading backslash (e.g., "alias", "examples").

## Value

A list of Rd nodes matching the section (possibly empty).
