# Get security vulnerabilities for a package

Retrieves known security vulnerabilities for a package from the Open
Source Vulnerabilities (OSV) database (<https://osv.dev/#use-the-api>)
and returns them as a data frame. Data retrieval is delegated to
\[fetch_osv_data()\], which handles an unavailable API or request
time-out gracefully (reporting a message and returning no data instead
of stopping).

## Usage

``` r
get_security_vulnerabilities(pkg_name, pkg_ver = NULL, ecosystem = "CRAN")
```

## Arguments

- pkg_name:

  Character. Name of the package to query.

- pkg_ver:

  Character. Optional package version. The OSV database is queried for
  every advisory affecting the package, and when a version is supplied
  only the advisories affecting that version are kept (filtered locally
  against each advisory's affected versions and ranges).

- ecosystem:

  Character. OSV ecosystem the package belongs to. Defaults to
  \`"CRAN"\`.

## Value

A data frame with one row per vulnerability and the columns:

- id:

  OSV / advisory identifier (e.g. \`"RSEC-2023-6"\`).

- summary:

  Short description of the vulnerability type.

- details:

  Detailed description of the vulnerability.

- introduced:

  Version in which the vulnerability was introduced.

- fixed:

  Version in which the vulnerability was fixed.

- modified:

  Timestamp the advisory was last modified.

- published:

  Timestamp the advisory was published.

An empty data frame (zero rows, same columns) is returned when there are
no known vulnerabilities or when the API could not be reached.

## Details

Each vulnerability is reported with its type via the \`summary\` field
(for example \`"Denial of Service (DoS) vulnerability"\`, \`"Arbitrary
Code Execution (ACE) Vulnerability"\`, \`"NULL pointer dereference
vulnerability"\`, or \`"Cross-site Request Forgery (CSRF)
vulnerability"\`) and a fuller description in \`details\`.

## Examples

``` r
if (FALSE) { # \dontrun{
get_security_vulnerabilities("commonmark", "1.7", ecosystem = "CRAN")
} # }
```
