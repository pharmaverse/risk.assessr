# Function to check suggested exported functions

This function checks the exported functions of target package against
the exported functions of Suggested dependencies to see if any Suggested
packages should be in Imports in the DESCRIPTION file

## Usage

``` r
check_suggested_exp_funcs(pkg_name, pkg_source_path, suggested_deps)
```

## Arguments

- pkg_name:

  \- name of the target package

- pkg_source_path:

  \- source of the target package

- suggested_deps:

  \- dependencies in Suggests

## Value

\- data frame with results of Suggests check
