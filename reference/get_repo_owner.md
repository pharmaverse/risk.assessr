# Extract GitHub repository owner from links

Given a vector of GitHub links and a package name, this function finds
the link corresponding to the package and extracts the GitHub repository
owner.

## Usage

``` r
get_repo_owner(links, pkg_name)
```

## Arguments

- links:

  A character vector of GitHub URLs.

- pkg_name:

  A string representing the name of the package.

## Value

A string containing the GitHub repository owner, or NA if not found.
