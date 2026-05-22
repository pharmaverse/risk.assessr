# Find an Rd document for a function using an index

Tries \`fun.Rd\`, then alias-based resolution via the index, and as a
last resort matches the topic name if it equals the function name.

## Usage

``` r
find_rd_for_fun(fun, db, idx = NULL)
```

## Arguments

- fun:

  Function name (character scalar).

- db:

  An Rd database list as returned by \`tools::Rd_db()\`.

- idx:

  Optional index from \`build_rd_index()\`. If \`NULL\`, it is built on
  demand.

## Value

\`NULL\` if not found, otherwise a list with \`rd\` (the Rd object) and
\`filename\` (the Rd filename).
