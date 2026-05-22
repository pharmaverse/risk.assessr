# Capture CRAN URL warnings and errors

This internal function attempts to open a CRAN URL and read its
contents. It captures and classifies warnings and errors related to
network issues, such as timeouts or inaccessible URLs.

## Usage

``` r
capture_cran_warning(cran_url, path)
```

## Arguments

- cran_url:

  Character. Base URL of the CRAN mirror.

- path:

  Character. Path to the resource on the CRAN server.

## Value

A list with two elements:

- status:

  Character string indicating the result type: "success", "url_error",
  "timeout", "error", "url_warning", "timeout_warning", or "warning".

- message:

  Character string with the captured warning or error message, or NULL
  if successful.

## Examples

``` r
if (FALSE) { # \dontrun{
  capture_cran_warning("http://cran.us.r-project.org", "src/contrib/Meta/archive.rds")
} # }
```
