# Assess an R package by name (deprecated)

Use \[risk_assess_pkg()\] with \`package\` instead.

## Usage

``` r
assess_pkg_r_package(package_name, version = NA, repos = getOption("repos"))
```

## Arguments

- package_name:

  Package name.

- version:

  Package version. Default \`NA\` uses latest.

- repos:

  Repository URLs. Default \`getOption("repos")\`.

## Value

Assessment results or \`NULL\`.
