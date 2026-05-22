# list all package exports

list all package exports

## Usage

``` r
get_exports(pkg_source_path)
```

## Arguments

- pkg_source_path:

  a file path pointing to an unpacked/untarred package directory

## Value

data.frame, with one column \`exported_function\`, that can be passed to
all downstream map\_\* helpers

## Examples

``` r
if (FALSE) { # \dontrun{
tmpdir <- tempdir()

# Locate the package source tarball bundled with risk.assessr
dp <- system.file("test-data", "test.package.0001_0.1.0.tar.gz",
                  package = "risk.assessr")

# Extract the source package into the temporary directory
utils::untar(dp, exdir = tmpdir)

# Find the extracted package directory (it should contain DESCRIPTION)
pkg_dirs <- list.dirs(tmpdir, full.names = TRUE, recursive = FALSE)
desc_dir <- pkg_dirs[file.exists(file.path(pkg_dirs, "DESCRIPTION"))]
stopifnot(length(desc_dir) == 1L)
pkg_source_path <- desc_dir

# Now operate on the *source* (no installation)
exports_df <- get_exports(pkg_source_path)

# Optional: inspect result (kept simple for examples)
head(exports_df)

# Clean up the extracted sources
unlink(pkg_source_path, recursive = TRUE, force = TRUE)
} # }
```
