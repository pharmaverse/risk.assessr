# Extract Package Names from a Dependency String

Parses a single package dependency string and extracts valid package
names, excluding "R" and ignoring version constraints or comments.

## Usage

``` r
extract_dependency_package_names(x)
```

## Arguments

- x:

  A character string representing a package dependency specification,
  such as \`"pkgA (\>= 1.0), pkgB, R (\>= 3.5.0)"\`.

## Value

A character vector of package names extracted from the input string. The
result excludes "R" and any version information.
