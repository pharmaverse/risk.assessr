# Assess an R Package traceability matrix from package name and version

This function use \`risk.assessr::create_traceability_matrix\` function
with only the package name and version

## Usage

``` r
generate_traceability_matrix(
  package_name,
  version = NA,
  repos = getOption("repos"),
  execute_coverage = FALSE
)
```

## Arguments

- package_name:

  A character string specifying the name of the package to assess.

- version:

  A character string specifying the version of the package to assess.
  Default is \`NA\`, which assesses the latest version.

- repos:

  A character string specifying the repo directly. Default is
  getOption("repos")

- execute_coverage:

  Logical (\`TRUE\`/\`FALSE\`). If \`TRUE\`, execute test coverage.

## Value

The function returns package traceability_matrix If the package cannot
be downloaded or installed, an error message is returned.

## Examples

``` r
if (FALSE) { # \dontrun{

results_no_test_covr <- generate_traceability_matrix(
 "here", 
 version = "1.0.1", 
 execute_coverage = FALSE
)

results_test_covr <- generate_traceability_matrix(
 "here", 
 version = "1.0.1", 
 execute_coverage = TRUE
)


print(results_no_test_covr)

print(results_test_covr)
} # }
```
