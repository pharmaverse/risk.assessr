# Assess package for risk metrics

Assess an R package for risk metrics. Use exactly one of: \* \`path\` –
path to a local .tar.gz archive, or \* \`package\` – package name to
fetch (optionally with \`version\`), or \* neither – opens an
interactive file chooser.

## Usage

``` r
risk_assess_pkg(
  path = NULL,
  package = NULL,
  version = NA,
  repos = getOption("repos")
)
```

## Arguments

- path:

  Path to a local .tar.gz package archive. Use only when not providing
  \`package\`.

- package:

  Package name to fetch from CRAN, Bioconductor, or internal repos. Use
  only when not providing \`path\`.

- version:

  (optional) Package version when using \`package\`. Default \`NA\` uses
  the latest available.

- repos:

  Repository URLs when fetching by \`package\`. Default is
  \`getOption("repos")\`.

## Value

List containing results (metrics, covr, trace matrix, R CMD check), or
\`NULL\` if the package cannot be assessed.

## Examples

``` r
if (FALSE) { # \dontrun{
# Local package (path or file chooser)
results <- risk_assess_pkg()
results <- risk_assess_pkg(path = "path/to/package.tar.gz")

# Package by name from repositories
results <- risk_assess_pkg(package = "here")
results <- risk_assess_pkg(package = "here", version = "1.0.1")
results <- risk_assess_pkg(package = "here", repos = "https://cloud.r-project.org")
} # }
```
