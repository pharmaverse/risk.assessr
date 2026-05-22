# Assess exported functions to namespace

Returns 1L if the package's NAMESPACE declares any exports (\`export\`,
\`exportClasses\`, \`exportMethods\`, \`exportPattern\` or
\`exportClassPatterns\`), 0L otherwise.

## Usage

``` r
assess_exports(data)
```

## Arguments

- data:

  pkg source path

## Value

integer scalar: 1L if any exports are declared, 0L otherwise.
