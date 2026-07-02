# Package index

## Risk assessment

Run a full risk assessment on a package (local archive or from
repositories).

- [`risk_assess_pkg()`](https://pharmaverse.github.io/risk.assessr/reference/risk_assess_pkg.md)
  : Assess package for risk metrics
- [`risk_assess_pkg_lock_files()`](https://pharmaverse.github.io/risk.assessr/reference/risk_assess_pkg_lock_files.md)
  : Process lock files
- [`get_frugal_metrics()`](https://pharmaverse.github.io/risk.assessr/reference/get_frugal_metrics.md)
  : Compute frugal risk metrics for an R package

## Reports & risk definitions

HTML reports, summaries, and risk metadata.

- [`generate_html_report()`](https://pharmaverse.github.io/risk.assessr/reference/generate_html_report.md)
  : Generate HTML Report for Package Assessment
- [`write_summary_report()`](https://pharmaverse.github.io/risk.assessr/reference/write_summary_report.md)
  : Write the risk assessment summary report
- [`get_risk_analysis()`](https://pharmaverse.github.io/risk.assessr/reference/get_risk_analysis.md)
  : Get Risk Analysis
- [`get_risk_definition()`](https://pharmaverse.github.io/risk.assessr/reference/get_risk_definition.md)
  : Get Risk Definition
- [`list_badges()`](https://pharmaverse.github.io/risk.assessr/reference/list_badges.md)
  : List badges image URLs from a local README

## Traceability matrix

Coverage mapping between tests and exported code.

- [`create_traceability_matrix()`](https://pharmaverse.github.io/risk.assessr/reference/create_traceability_matrix.md)
  : Create a Traceability Matrix
- [`generate_traceability_matrix()`](https://pharmaverse.github.io/risk.assessr/reference/generate_traceability_matrix.md)
  : Assess an R Package traceability matrix from package name and
  version

## Package hosting & downloads

Resolve tarballs from CRAN, Bioconductor, and internal mirrors.

- [`get_package_tarfile()`](https://pharmaverse.github.io/risk.assessr/reference/get_package_tarfile.md)
  : Download R Package Source Tarball
- [`get_host_package()`](https://pharmaverse.github.io/risk.assessr/reference/get_host_package.md)
  : Extract and Validate Package Hosting Information
- [`get_internal_package_url()`](https://pharmaverse.github.io/risk.assessr/reference/get_internal_package_url.md)
  : Get Internal Package URL
- [`get_cran_package_url()`](https://pharmaverse.github.io/risk.assessr/reference/get_cran_package_url.md)
  : Get CRAN Package URL
- [`get_cran_total_downloads()`](https://pharmaverse.github.io/risk.assessr/reference/get_cran_total_downloads.md)
  : Get CRAN Total or Recent Downloads for a Package
- [`get_package_download_cran()`](https://pharmaverse.github.io/risk.assessr/reference/get_package_download_cran.md)
  : Get CRAN Daily Downloads for a Package
- [`get_package_download_bioconductor()`](https://pharmaverse.github.io/risk.assessr/reference/get_package_download_bioconductor.md)
  : Get Bioconductor Package Download Statistics
- [`check_cran_package()`](https://pharmaverse.github.io/risk.assessr/reference/check_cran_package.md)
  : Check if a Package Exists on CRAN
- [`check_and_fetch_cran_package()`](https://pharmaverse.github.io/risk.assessr/reference/check_and_fetch_cran_package.md)
  : Check and Fetch CRAN Package
- [`get_versions()`](https://pharmaverse.github.io/risk.assessr/reference/get_versions.md)
  : Get Package Versions
- [`get_bioconductor_package_url()`](https://pharmaverse.github.io/risk.assessr/reference/get_bioconductor_package_url.md)
  : Retrieve Bioconductor Package URL
- [`fetch_bioconductor_releases()`](https://pharmaverse.github.io/risk.assessr/reference/fetch_bioconductor_releases.md)
  : Fetch Bioconductor Release Announcements
- [`parse_bioconductor_releases()`](https://pharmaverse.github.io/risk.assessr/reference/parse_bioconductor_releases.md)
  : Parse Bioconductor Release Announcements
- [`fetch_bioconductor_package_info()`](https://pharmaverse.github.io/risk.assessr/reference/fetch_bioconductor_package_info.md)
  : Fetch Bioconductor Package Information
- [`get_security_vulnerabilities()`](https://pharmaverse.github.io/risk.assessr/reference/get_security_vulnerabilities.md)
  : Get security vulnerabilities for a package

## Dependencies & reverse dependencies

Dependency trees, session deps, and CRAN/Bioconductor reverse deps.

- [`build_dependency_tree()`](https://pharmaverse.github.io/risk.assessr/reference/build_dependency_tree.md)
  : Build a Dependency Tree for an R Package
- [`download_and_parse_dependencies()`](https://pharmaverse.github.io/risk.assessr/reference/download_and_parse_dependencies.md)
  : Download and Parse Dependencies of an R Package
- [`fetch_all_dependencies()`](https://pharmaverse.github.io/risk.assessr/reference/fetch_all_dependencies.md)
  : Fetch All Dependencies for a Package
- [`print_tree()`](https://pharmaverse.github.io/risk.assessr/reference/print_tree.md)
  : Print a Package Dependency Tree
- [`cran_revdep()`](https://pharmaverse.github.io/risk.assessr/reference/cran_revdep.md)
  : Find Reverse Dependencies of a CRAN Package
- [`bioconductor_reverse_deps()`](https://pharmaverse.github.io/risk.assessr/reference/bioconductor_reverse_deps.md)
  : Find Bioconductor Package Reverse Dependencies
- [`cran_packages()`](https://pharmaverse.github.io/risk.assessr/reference/cran_packages.md)
  : Retrieve the List of CRAN Packages (Internal)
- [`extract_package_version()`](https://pharmaverse.github.io/risk.assessr/reference/extract_package_version.md)
  : Extract the Installed Version of a Package
- [`parse_package_info()`](https://pharmaverse.github.io/risk.assessr/reference/parse_package_info.md)
  : Parse Package Information from CRAN Archive

## GitHub & repository activity

GitHub metadata and commit/issue activity.

- [`get_github_data()`](https://pharmaverse.github.io/risk.assessr/reference/get_github_data.md)
  : Fetch GitHub Repository Data
- [`get_commits_since()`](https://pharmaverse.github.io/risk.assessr/reference/get_commits_since.md)
  : Retrieve GitHub Commits as Weekly Counts (using curl)
- [`count_commits_last_months()`](https://pharmaverse.github.io/risk.assessr/reference/count_commits_last_months.md)
  : Count Commits in the Last Months
- [`average_issue_close_time()`](https://pharmaverse.github.io/risk.assessr/reference/average_issue_close_time.md)
  : Calculate Average Time to Close GitHub Issues

## PubMed

Literature counts for packages linked to PubMed.

- [`get_pubmed_count()`](https://pharmaverse.github.io/risk.assessr/reference/get_pubmed_count.md)
  : Get Total Number of PubMed Articles for a Search Term
- [`get_pubmed_by_year()`](https://pharmaverse.github.io/risk.assessr/reference/get_pubmed_by_year.md)
  : Get Annual PubMed Article Counts for a Search Term

## Helper functions

Low-level and programmatic helpers (coverage runners, test mapping,
package inspection, thresholds).

- [`assess_pkg_r_package()`](https://pharmaverse.github.io/risk.assessr/reference/assess_pkg_r_package.md)
  : Assess an R package by name (deprecated)
- [`dependsOnPkgs()`](https://pharmaverse.github.io/risk.assessr/reference/dependsOnPkgs.md)
  : Determine Packages that Depend on Given Packages
- [`detect_version_conflicts()`](https://pharmaverse.github.io/risk.assessr/reference/detect_version_conflicts.md)
  : Detect Version Conflicts from dependency tree
- [`extract_thresholds_by_id()`](https://pharmaverse.github.io/risk.assessr/reference/extract_thresholds_by_id.md)
  : Extract risk thresholds by id
- [`extract_thresholds_by_key()`](https://pharmaverse.github.io/risk.assessr/reference/extract_thresholds_by_key.md)
  : Extract risk thresholds by key
- [`extract_version()`](https://pharmaverse.github.io/risk.assessr/reference/extract_version.md)
  : Extract Package Version from File Path
- [`get_exports()`](https://pharmaverse.github.io/risk.assessr/reference/get_exports.md)
  : list all package exports
- [`get_pkg_name()`](https://pharmaverse.github.io/risk.assessr/reference/get_pkg_name.md)
  : get package name for display
- [`get_session_dependencies()`](https://pharmaverse.github.io/risk.assessr/reference/get_session_dependencies.md)
  : Get Dependencies
- [`get_suggested_exp_funcs()`](https://pharmaverse.github.io/risk.assessr/reference/get_suggested_exp_funcs.md)
  : Function to get suggested exported functions
- [`install_package_local()`](https://pharmaverse.github.io/risk.assessr/reference/install_package_local.md)
  : Install package locally
- [`is_base()`](https://pharmaverse.github.io/risk.assessr/reference/is_base.md)
  : Check if a Package is a Base or Recommended R Package
- [`modify_description_file()`](https://pharmaverse.github.io/risk.assessr/reference/modify_description_file.md)
  : Modify the DESCRIPTION File in a R Package Tarball
- [`parse_html_version()`](https://pharmaverse.github.io/risk.assessr/reference/parse_html_version.md)
  : Parse HTML Content for Package Versions
- [`set_up_pkg()`](https://pharmaverse.github.io/risk.assessr/reference/set_up_pkg.md)
  : Creates information on package installation
