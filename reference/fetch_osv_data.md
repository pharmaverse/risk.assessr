# Retrieve raw vulnerability data from the OSV API

Sub-function that queries the Open Source Vulnerabilities (OSV) database
(<https://osv.dev/#use-the-api>) for a single package using \`curl\`.
The query is sent as a POST request to the OSV \`query\` endpoint. All
network and parsing steps are wrapped in \`tryCatch\` so that an
unavailable API or a request time-out reports a message and returns
\`NULL\` rather than stopping the calling function.

## Usage

``` r
fetch_osv_data(pkg_name, pkg_ver = NULL, ecosystem = "CRAN", timeout = 30)
```

## Arguments

- pkg_name:

  Character. Name of the package to query.

- pkg_ver:

  Character. Optional package version. When supplied, OSV only returns
  vulnerabilities affecting that version.

- ecosystem:

  Character. OSV ecosystem the package belongs to. Defaults to
  \`"CRAN"\`.

- timeout:

  Numeric. Maximum number of seconds to wait for the request. Defaults
  to 30.

## Value

A list parsed from the OSV JSON response (with a \`vulns\` element when
vulnerabilities are found), or \`NULL\` if the API is unavailable, times
out, or returns an error status.

## Examples

``` r
if (FALSE) { # \dontrun{
fetch_osv_data("commonmark", ecosystem = "CRAN")
} # }
```
