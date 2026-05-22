# Build a fast lookup index for an Rd database

Provides (1) an alias index, mapping \`alias -\> filename\`, and (2) a
topic index, mapping \`filename -\> \name\` (topic).

## Usage

``` r
build_rd_index(db)
```

## Arguments

- db:

  An Rd database list as returned by \`tools::Rd_db()\`.

## Value

A list with elements \`alias_index\` (environment) and \`topic_by_file\`
(named character vector).
