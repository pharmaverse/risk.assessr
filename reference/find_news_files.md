# Paths to NEWS files for a package source tree

Searches the same locations and basenames that
[`utils::news`](https://rdrr.io/r/utils/news.html) uses for an installed
package (via `tools:::.build_news_db`): `NEWS.Rd`, `NEWS.md`, and
extensionless `NEWS`. For a source checkout, those files are collected
from the package root, `doc/`, `vignettes/`, and under `inst/`
(recursively, including `inst/NEWS` as in `tools::news2Rd`).

## Usage

``` r
find_news_files(pkg_source_path)
```

## Arguments

- pkg_source_path:

  Source path of the package.

## Value

Character vector of absolute file paths (possibly empty).
