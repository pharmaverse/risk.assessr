<!-- README.md is generated from README.Rmd. Please edit that file -->

# risk.assessr <a><img src="man/figures/logo.png" align="right" height="138"/></a>

<!-- badges: start -->
![R-CMD-check](https://img.shields.io/badge/R%20CMD%20check-Passing-brightgreen.svg)
![Test Coverage](https://img.shields.io/badge/coverage-94%25-brightgreen.svg)
![Pharmaverse](http://pharmaverse.org/shields/risk.assessr.svg)
<!-- badges: end -->

# risk.assessr

# Overview

risk.assessr helps in the initial determining of a package's reliability and security in terms of maintenance, documentation, and dependencies.

This package is designed to carry out a risk assessment of R packages at the beginning of the validation process (either internal or open source).

It calculates risk metrics such as:

**Core metrics** - includes R command check, unit test coverage and composite coverage of dependencies

**Documentation metrics** - availability of vignettes, news tracking, example(s), return object description for exported functions, and type of license

**Dependency Metrics** - package dependencies and reverse dependencies

It also calculates a:

**Traceability matrix** - matching the function / test descriptions to tests and match to test pass/fail

# Description

This package executes the following tasks:

1.  upload the source package(`tar.gz` file)

2.  Unpack the `tar.gz` file

3.  Install the package locally

4.  Run code coverage

5.  Run a traceability matrix

6.  Run R CMD check

7.  Run risk assessment metrics using default or user defined weighting

# Notes

This package fixes a number of errors in `pharmaR/riskmetric`

1.  running R CMD check and code coverage with locally installed packages
2.  user defined weighting works
3.  `Suggests` added to checking dependencies
4.  `assess_dependencies` and `assess_reverse_dependencies` has sigmoid point increased
5.  `assess_dependencies` has value range changed to fit in with other scoring metrics

# Package Installation

## from [Github](https://github.com/Sanofi-Public/risk.assessr)

-   Create a `Personal Access Token` (PAT) on `github`

    -   Log into your `github` account
    -   Go to the token settings URL using the [Token Settings URL](https://github.com/settings/tokens)

-   Create a `.Renviron` file with your GITHUBTOKEN as:

<!-- -->

```         
# .Renviron
GITHUBTOKEN=dfdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxfdf
```

-   restart R session
-   You can install the package with:

<!-- -->

```         
auth_token = Sys.getenv("GITHUBTOKEN")
devtools::install_github("Sanofi-Public/risk.assessr", ref = "main", auth_token = auth_token)
```

## from [CRAN](https://CRAN.R-project.org/package=risk.assessr)

``` r
options(repos = "http://cran.us.r-project.org")
installed.packages(risk.asssessr)
```

# Usage

## Assessing your own package

To assess your package, do the following steps:

1 - save your package as a `tar.gz` file

-   This can be done in `RStudio` -\> `Build Tab` -\> `More` -\> `Build Source Package`

2 - Run the following code sample by loading or add path parameter to your `tar.gz` package source code

Set repository options

``` r
options(repos = c(
  RSPM = "http://cran.us.r-project.org",
  INTERNAL_RSPM = "<your_internal_RSPM>"
))
```

This sets up repository sources for R packages allows you to access both public (CRAN/Bioconductor) and internal packages

When you install or load packages, R will:

First check the RSPM repository for CRAN/Bioconductor packages. Then look in the INTERNAL repository for internal-specific packages. Finally, search INTERNAL_RSPM if packages aren't found in the previous locations

``` r
# for local tar.gz R package
risk_assess_package <- risk_assess_pkg()

risk_assess_package <- risk_assess_pkg(path/to/your/package)
```

## Assessing from local renv.lock file

This function processes `renv.lock` to produce risk metric data for each package.

``` r
# for local renv.lock file

risk_assess_package <- risk_assess_pkg_lock_files(path/to/your/lockfile)
```

Note: This process can be very time-consuming and is recommended to be performed as a batch job or within a GitHub Action.

## Assessing Open source R package on CRAN or bioconductor

To check a source code package from `CRAN` or `bioconductor`, run the following code:

``` r
risk_assess_package <- assess_pkg_r_package(package_name, package_version)
```

# Metrics and Risk assessment

| Key Metrics         | Reason                                                                            | where to find them in Metrics and Risk assessment |
|---------------------|------------------|---------------------------------|
| RCMD check          | series of 45 package checks of tests, package structure, documentation            | `check` element in `results` list, check_list     |
| test coverage       | unit test coverage                                                                | `covr` element in `results` list, covr_list       |
| risk analysis       | rules and thresholds to identify risks                                            | risk_analysis                                     |
| traceability matrix | maps exported functions to test coverage, documentation by risk and function type | tm_list                                           |

## results

```         
results
├── pkg_name: "admiral"
├── pkg_version: "1.0.2"
├── pkg_source_path
├── date_time
├── executor
├── sysname, version, release, machine, comments
├── license: 1
├── license_name: "Apache License (>= 2)"
├── size_codebase: 0.9777
├── has_bug_reports_url, has_examples, has_maintainer, has_news
├── has_source_control, has_vignettes, has_website, news_current
├── export_help: 0
├── check: 0
├── covr: 0
├── dependencies
│   ├── imports: [list of packages with versions]
│   └── suggests: [list of packages with versions]
├── suggested_deps: [list of 5 dependency issues]
├── author
│   ├── maintainer: [Ben Straub info]
│   ├── funder: [list of organizations]
│   └── authors: [list of contributors]
├── host
│   ├── github_links
│   ├── cran_links
│   ├── internal_links
│   └── bioconductor_links
├── github_data
│   ├── created_at
│   ├── stars, forks
│   ├── date
│   ├── recent_commits_count
│   └── open_issues
├── download
│   ├── total_download
│   └── last_month_download
├── rev_deps: [list of reverse dependencies]
├── version_info
│   ├── all_versions: [list of version/date pairs]
│   ├── last_version
│   └── difference_version_months
├── tests
│   ├── has_testthat
│   ├── has_snaps
│   ├── has_testit
│   ├── n_golden_tests
│   └── n_test_files
└── risk_profile: "High"
```

[More info Here](https://probable-chainsaw-kgro2o7.pages.github.io/articles/risk.assessr_metric.html)

## covr_list

```         
covr_list
├── total_cov: "NA"
└── res_cov
    ├── name: "admiral"
    ├── coverage
    │   ├── filecoverage: null
    │   └── totalcoverage: "NA"
    └── errors: [callr traceback]
```

## 🔍 check_list

```         
check_list
├── res_check
│   ├── stdout, stderr, status, duration
│   ├── errors, warnings, notes
│   ├── checkdir
│   └── description (DESCRIPTION file content)
└── check_score: 0
```

## risk_analysis

```         
risk_analysis
├── dependencies_count: "low"
├── later_version: "high"
├── code_coverage: "high"
├── last_month_download: "high"
├── license: "low"
├── reverse_dependencies_count: "medium"
├── documentation_score: "high"
└── cmd_check: "high"
```

[More info Here](https://probable-chainsaw-kgro2o7.pages.github.io/articles/define_custom_risk_rules.html)

# Advanced features

## Traceability Matrix

```         
tm_list
├── pkg_name: "admiral"
└── coverage
    ├── filecoverage: 0
    └── totalcoverage: 0
```

[More info Here](https://probable-chainsaw-kgro2o7.pages.github.io/articles/Traceability_matrix.html)

### suggested_deps

```         
suggested_deps
├── [1]
│   ├── source: "create_period_dataset"
│   ├── suggested_function: "matches"
│   ├── targeted_package: "testthat"
│   └── message: "Please check if the targeted package should be in Imports"
├── [2]
│   ├── source: "create_single_dose_dataset"
│   ├── suggested_function: "it"
│   ├── targeted_package: "testthat"
│   └── message: "Please check if the targeted package should be in Imports"
├── [3]
│   ├── source: "derive_vars_merged"
│   ├── suggested_function: "it"
│   ├── targeted_package: "testthat"
│   └── message: "Please check if the targeted package should be in Imports"
├── [4]
│   ├── source: "list_tte_source_objects"
│   ├── suggested_function: "br"
│   ├── targeted_package: "htmltools"
│   └── message: "Please check if the targeted package should be in Imports"
├── [5]
│   ├── source: "use_ad_template"
│   ├── suggested_function: "it"
│   ├── targeted_package: "testthat"
│   └── message: "Please check if the targeted package should be in Imports"
```

# Generate HTML risk report

[More info Here](https://probable-chainsaw-kgro2o7.pages.github.io/articles/generate_html_report.html)

# Current/Future directions

-   Produce database of risk assessment for Sanofi packages
-   Github actions

# Publication/presentation

# PHUSE 2025 Presentations -- Sanofi

1.  **Conference:** Connect 2025\
    **Location:** Orlando, US\
    **Session ID:** OS17\
    **Title:** *Risk.assessr: A Tool for Assessing and Mitigating Risks with Open-Source R Packages in Clinical Trials*\
    **Presenters:** Andre Couturier, Edward Gillian\
    **Authors:** Edward Gillian, Hugo Bottois, Paulin Charliquart, Andre Couturier\
    **Company:** Sanofi\
    **Materials**
    -   [Presentation (PDF)](https://phuse.s3.eu-central-1.amazonaws.com/Archive/2025/Connect/US/Orlando/PRE_OS17.pdf)\
    -   [Paper (PDF)](https://phuse.s3.eu-central-1.amazonaws.com/Archive/2025/Connect/US/Orlando/PAP_OS17.pdf)
2.  **Conference:** PHUSE SDE 2025\
    **Location:** Beijing, China\
    **Title:** *CI/CD in R Package Development with Integrated Risk Assessment*\
    **Presenter:** Neo Yang\
    **Authors:** Edward Gillian, Hugo Bottois, Paulin Charliquart, Andre Couturier\
    **Company:** Sanofi\
    **Materials**
    -   [Presentation (PDF)](https://phuse.s3.eu-central-1.amazonaws.com/Archive/2025/SDE/APAC/Beijing/PRE_Beijing07.pdf)
3.  **Conference:** EU Connect 2025\
    **Location:** Hamburg, Germany\
    **Session ID:** CT10\
    **Title:** *Risk.assessr: Extracting OOP Function Details*\
    **Presenter:** Edward Gillian\
    **Authors:** Edward Gillian, Hugo Bottois, Paulin Charliquart, Andre Couturier\
    **Company:** Sanofi\
    **Materials / Status:**
    -   *Ongoing*
4.  **Conference:** R/Pharma 2025 APAC\
    **Location:** Online\
    **Session ID:** Ongoing\
    **Title:** *risk.assessr: extending its use in the package validation process*\
    **Presenter:** Hugo Bottois\
    **Authors:** Edward Gillian, Hugo Bottois, Paulin Charliquart, Andre Couturier\
    **Company:** Sanofi\
    **Materials / Status:**
    -   *Ongoing*

# Citation

Gillian E, Bottois H, Charliquart P, Couturier A (2025). risk.assessr: Assessing Package Risk Metrics. R package version 2.0.0, <https://probable-chainsaw-kgro2o7.pages.github.io/>.

```         
@Manual{,
  title = {risk.assessr: Assessing Package Risk Metrics},
  author = {Edward Gillian and Hugo Bottois and Paulin Charliquart and Andre Couturier},
  year = {2025},
  note = {R package version 2.0.0},
  url = {https://probable-chainsaw-kgro2o7.pages.github.io/},
}
```

# Acknowledgements

The project is inspired by the [`riskmetric`](https://github.com/pharmaR/riskmetric) package and the [`mpn.scorecard`](https://github.com/metrumresearchgroup/mpn.scorecard) package and draws on some of their ideas and functions.
