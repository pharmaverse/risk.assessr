# Get exported function names with a NAMESPACE-source fallback.

Attempts to obtain exported function names from the installed namespace.
If the namespace is not available - for example when \`R CMD INSTALL\`
failed because the package has no \`R/\` folder on stricter R versions -
falls back to parsing \`NAMESPACE\` from \`pkg_source_path\` via
\[get_exports_from_source()\]. In the fallback path the result includes
every declared export, because function-ness cannot be verified without
a loaded namespace.

## Usage

``` r
get_exported_function_names(pkg_name, pkg_source_path)
```

## Arguments

- pkg_name:

  Character scalar; package name.

- pkg_source_path:

  Path to the unpacked package source.

## Value

Character vector of exported names (possibly empty).
