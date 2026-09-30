# Retrieve raw vulnerability data from the OSV API

Internal helper that queries the Open Source Vulnerabilities (OSV)
database (<https://osv.dev/#use-the-api>) for a package using \`curl\`.
The query is sent as a POST request to the OSV \`query\` endpoint. When
the OSV API paginates results, all pages are retrieved automatically and
merged into a single response before being returned.

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

  Numeric. Maximum number of seconds to wait for each API request.
  Defaults to 30.

## Value

A list parsed from the OSV JSON response. When vulnerabilities are
found, the returned object contains a \`vulns\` element comprising
vulnerabilities aggregated across all response pages. Returns \`NULL\`
if the API is unavailable, a request fails, the response cannot be
parsed, or the API returns a non-success status.

## Details

All network and JSON parsing operations are wrapped in \`tryCatch\` so
that an unavailable API, request timeout, parsing failure, or
non-success HTTP response reports a message and returns \`NULL\` rather
than stopping the calling function.
