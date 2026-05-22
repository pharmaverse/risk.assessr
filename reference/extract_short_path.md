# Helper to extract "R/\<file\>" from any path by taking the last two components

Helper to extract "R/\<file\>" from any path by taking the last two
components

## Usage

``` r
extract_short_path(long_file_name)
```

## Arguments

- long_file_name:

  A string containing the full file path (supports forward slash or
  backslash))

## Value

A character string composed of the last two path components, e.g.,
"R/add.R"
