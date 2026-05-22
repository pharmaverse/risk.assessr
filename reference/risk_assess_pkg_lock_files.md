# Process lock files

This function processes \`renv.lock\` and \`pak.lock\` files to produce
risk metric data

## Usage

``` r
risk_assess_pkg_lock_files(input_data)
```

## Arguments

- input_data:

  \- path to a lock file

## Value

assessment_results - nested list containing risk metric data

## Examples

``` r
if (FALSE) { # \dontrun{
  input_data <- ("path/to/mypak.lock")
  pak_results <- risk_assess_pkg_lock_files(input_data) 
  print(pak_results)
 } # } 
```
