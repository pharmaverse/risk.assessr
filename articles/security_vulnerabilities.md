# Security vulnerabilities

## Introduction

The security vulnerabilities feature checks for known, publicly
disclosed vulnerabilities in the R package being assessed. It is
accessed through:

- [`get_security_vulnerabilities()`](https://pharmaverse.github.io/risk.assessr/reference/get_security_vulnerabilities.md)
  — the exported function that retrieves advisories for a package.

It also runs automatically as part of a full assessment via
[`risk_assess_pkg()`](https://pharmaverse.github.io/risk.assessr/reference/risk_assess_pkg.md)
/
[`assess_pkg()`](https://pharmaverse.github.io/risk.assessr/reference/assess_pkg.md).

------------------------------------------------------------------------

## Where the data comes from

Advisories are retrieved from the **Open Source Vulnerabilities (OSV)**
database (<https://osv.dev>) using a `POST` request to the query
endpoint `https://api.osv.dev/v1/query`. For R packages, OSV serves
advisories from the [R Consortium
r-advisory-database](https://github.com/RConsortium/r-advisory-database),
which carry `RSEC-*` identifiers.

The package is queried by name only within the `"CRAN"` ecosystem. All
advisories for the package are fetched, then filtered locally against
the installed version. Querying by name (rather than name + version)
avoids missing range-based advisories that a version-scoped OSV query
can silently omit.

------------------------------------------------------------------------

## Load the package

``` r

library(risk.assessr)
```

------------------------------------------------------------------------

## Retrieving vulnerabilities directly

``` r

vulns <- get_security_vulnerabilities("commonmark", "1.7")
vulns
```

The function returns a data frame with one row per advisory and the
following columns:

- `id` — advisory identifier (e.g. `RSEC-2023-6`)
- `summary` — short vulnerability type
- `details` — full description
- `introduced` — version the issue was introduced
- `fixed` — version the issue was fixed
- `modified`, `published` — advisory timestamps

If no advisories apply, a zero-row data frame with the same columns is
returned. Omitting the version returns every advisory known for the
package.

------------------------------------------------------------------------

## Within a full assessment

When you assess a package, the vulnerabilities are stored in the results
object:

``` r

result <- risk_assess_pkg(package = "commonmark", version = "1.7")
result$results$vulnerabilities
```

------------------------------------------------------------------------

## How results are reported

**Summary report** — vulnerabilities appear as a single metric,
“Security Vulnerabilities”, showing the count of advisories found. Any
count of one or more is scored **High** risk; zero is scored **Low**.
This contributes to the overall recommendation alongside the other risk
metrics.

**HTML report** — when advisories are found, the report renders a
red-headed, searchable table listing every advisory (`ID`, `Summary`,
`Details`, `Introduced`, `Fixed`, `Modified`, `Published`). When none
are found, a green “No security vulnerabilities” banner is shown
instead.

------------------------------------------------------------------------

## Limitations

- Only the `"CRAN"` ecosystem is queried; Bioconductor is not
  auto-detected.
- The feature requires network access to the OSV API.
- API failures return an empty result, so absence of rows is not by
  itself a guarantee that a package is free of vulnerabilities — check
  the console messages.
- Vulnerability scoring is not configurable through
  `risk-definition.json` at the moment.
