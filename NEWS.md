# risk.assessr 4.1.0

## New Features

- add CRAN-safe test skip helpers `skip_if_repo_unavailable()` and
  `skip_if_test_data_missing()` to fix "package_installed not found" failures (#54)
- refactor `create_traceability_matrix()` to join on a normalized `.join_key`
  for reliable coverage-to-function matching across path formats (#52)

# risk.assessr 4.0.0

## New Features

 - add test.assessr dependency to process unit test coverage
 - remove unit test coverage code, docs, tests and dependencies
 - reorganisation of documentation by topic
 - check R folder recursively 
 - check for NEWS in different locations
 - check different hosting platforms for repos
 - add and update average_issue_close_time
 - refactor create_traceability_matrix
 - refactor check_suggested_exp_funcs
 - refactor assess_exports
 - update modify_description unpack_tarball
 - add skip_if_repo_unavailable to tests
 - update assess_size_codebase to handle no R folder
 - update tests to include licenses

# risk.assessr 3.1.1

## New Features

 - patch release includes `risk_assess_pkg()`
   and `assess_pkg_r_package()` feature to retrieve latest package versions

# risk.assessr 3.1.0

## New Features

 - improved assessment of documentation and examples
 
 - summary decision report for validation process
 
 - refactor fetching source files
 
 - updated stringr and kableExtra versions
 

# risk.assessr 3.0.1

## New Features

- this version fixes issues found in the CRAN check

# risk.assessr 3.0.0

## New Features

- **fine-grained traceability matrices**:

  - new traceability matrices (tms) in `generate_html_report`:
    - tms showing functions by test coverage e.g. `High Risk`, `Medium Risk`, `Low Risk`
    - tms showing function type e.g. `Defunct`, `Imported`, `Re-exported`, `Experimental`
    - Test coverage made optional
    

- **data retrieval from different sources**:

  - more extensive data retrieval from `CRAN`, `Bioconductor` and `GitHub` including:
  
    - retrieval of the URLs for packages
    - available package versions
    - popularity metrics e.g. monthly and cumulative CRAN/Bioconductor downloads and git commits
    - number of citation data from PubMed e.g. article counts by year
  

- **define your own risk rules** 

  - Add risk analysis that identify risks (Low, Medium, High) based on risk.assessr metric values and thresholds
  - create your own rules or use the default rules to suit your R package validation requirements
  
- **test configuration checks**

  - identify testing framework/s such as testthat and testit
  - count number of tests and golden test files  
  
- **dependency tree**

  - Create and display data about your package and its dependencies including package versions
   
- **generate report path**

  - `generate_html_report` will create a default report path if the user does not specify one
 
- **retrieve readme badge**
  - `list_badges` will fetch the list of badge in the readme and return key-value

- **test cleanup**
  - tests that use `tar` files located in `inst/test-data` have improved clean up using `withr::defer` and `unlink` 
   change `generate_html_report` and `test-generate_html_report` to make them CRAN compliant
  
- **vignette build**
  - vignettes that access `CRAN` set to `eval=FALSE` to aid in detritus cleanup
  
# risk.assessr 2.0.0

## New Features

- **Author Metadata Expansion**:

  - Added `$author` section including `maintainer`, `funder`, and a full list of contributing authors with ORCID IDs and roles.

- **Hosting Metadata Extraction**:

  - New `$host` section includes GitHub and CRAN, Bioconductor and internal package

- **GitHub Repository**:

  - Added `$github_data` with:
    - `created_at`
    - `stars`
    - `forks`
    - `recent_commits_count`

- **CRAN download**:

  - Added `$download` with:
    - `total_download`
    - `last_month_download`

- **Package version**:

  - Added `$version_info` with:
    - `available_version`
    - `last_version`

- **Bioconductor compatibility**:

  - `assess_pkg_r_package()` function now fetches bioconductor source package
  
- **renv.lock processing**:

  - `risk_assess_pkg_lock_files()` function now processes `renv.lock` and `pak.lock` files
  
- **Suggested Dependency Analysis**:

  - Introduced `$suggested_deps` output as a tibble with `source`, `suggested_function`, `targeted_package`, and contextual `message`.

- **Traceability Matrix**:

  - now processes and reports on regular, S3, and S4 functions.

- **Package validation report**:

  - HTML report creation with interactive features for package validation

### Improvements

- **Structured Dependency Extraction**:

  - Dependencies are now returned as structured nested lists under `$dependencies$imports` and `$dependencies$suggests`, replacing the previous flat string format.
  
  - Each suggested package now includes installed version from `getsession()`
  - Added `$license_name` for readable license detection, e.g., `"MIT + file LICENSE"`
  - Added `$rev_deps` returning list reverse dependency 
  - risk_assess_pkg() now includes an optional parameter "path" for locally stored package
  - remove `httr2` and `tibble` dependencies

# risk.assessr 1.0.0

First package version inspired by `riskmetric`.

Package features include:

 - Run CMD, test coverage
 - Traceability Matrix
 - Metadata (Date, system, OS)
 - Quality extraction metrics (documentation, license, examples, vignettes)
 - `assess_pkg_r_package()` function fetches source code from CRAN






















  