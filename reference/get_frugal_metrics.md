# Compute frugal risk metrics for an R package

A lightweight ("frugal") variant of \[risk_assess_pkg()\] that skips the
most expensive parts of a full assessment:

\* the test suite is \*\*not\*\* executed (R CMD check is run with
\`–no-tests\`, sourced from \[setup_rcmdcheck_args()\] with \`check_type
= "2"\`), \* unit-test coverage is \*\*not\*\* computed (no call to
\`test.assessr::get_package_coverage()\`), and \* remote metadata
(CRAN/Bioconductor versions, GitHub stats, downloads, reverse
dependencies) is \*\*not\*\* fetched.

What is still produced:

\* documentation risk metrics (\[doc_riskmetric()\]), \* R CMD check
score (with the frugal flag set described above), \* direct & session
dependencies, exports, author and license metadata, \* a traceability
matrix without coverage (\[create_traceability_matrix()\] with
\`execute_coverage = FALSE\`), \* a \`risk_analysis\` block
(\[get_risk_analysis()\]).

## Usage

``` r
get_frugal_metrics(package_name, version = NA, repos = getOption("repos"))
```

## Arguments

- package_name:

  Character. Name of the package to assess.

- version:

  Character or \`NA\`. Specific version to fetch. Default \`NA\` uses
  the latest available.

- repos:

  Character. Repository URLs to use when fetching the tarball. Defaults
  to \`getOption("repos")\`.

## Value

A named list with the same top-level shape as \[risk_assess_pkg()\]:

- \`results\`:

  Risk-metric results list (with frugal placeholders).

- \`covr_list\`:

  Coverage placeholder produced by \[init_frugal_covr_list()\].

- \`tm_list\`:

  Traceability matrix (no coverage).

- \`check_list\`:

  R CMD check output from \[run_rcmdcheck()\].

- \`risk_analysis\`:

  Risk levels from \[get_risk_analysis()\].

Returns \`NULL\` if the tarball cannot be fetched or the package cannot
be unpacked.

## See also

\[risk_assess_pkg()\], \[setup_rcmdcheck_args()\], \[set_up_pkg()\],
\[init_frugal_results()\], \[init_frugal_covr_list()\].

## Examples

``` r
if (FALSE) { # \dontrun{
frugal <- get_frugal_metrics("here", version = "1.0.1")
} # }
```
