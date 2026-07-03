## Test environments

-   local Windows 11 x64 (build 26100) R version 4.4.1 (2024-06-14 ucrt)
-   local CentOS Linux 7 (Core) R version 4.2.1 (2022-06-23)
-   macOS Sonoma 14.7.5 (on GitHub Actions), R version 4.5.0 (2025-04-11)
-   Windows Server 2022 x64 (build 20348) (on GitHub Actions), R version 4.5.0 (2025-04-11 ucrt)
-   Ubuntu 24.04.2 LTS (on GitHub Actions), R Under development (unstable) (2025-05-11 r88197)
-   Ubuntu 24.04.2 LTS (on GitHub Actions), R version 4.5.0 (2025-04-11)
-   Ubuntu 24.04.2 LTS (on GitHub Actions), R version 4.4.3 (2025-02-28)

## Changes in version 4.1.0
* **New dependency `test.assessr` (>= 2.1.0)** is now in `Imports`.
  Unit-test-coverage processing has been extracted out of `risk.assessr`
  and is now delegated to `test.assessr`. The coverage code, its
  documentation, tests, and previous coverage-related dependencies have
  been removed from this package accordingly. `test.assessr` is available
  on CRAN at the required version.
* **CRAN-safe test skip helpers (PR #54 / branch 53).**
  Added two helpers in `tests/testthat/helper-skip_conditions.R`:
  - `skip_if_repo_unavailable()` — skips network-dependent tests when no
    CRAN repo is configured or the repository is unreachable (also calls
    `skip_on_cran()`).
  - `skip_if_test_data_missing()` — skips tests when a required test-data
    fixture is absent (`system.file()` returns "" on CRAN check machines
    for large tarballs not shipped with the installed package), which
    previously caused `set_up_pkg()` / `install_package_local()` to error
    with "object 'package_installed' not found".
  Affected tests were updated to call these guards so they no longer fail
  on CRAN or offline check machines.
* **Refactored `create_traceability_matrix()` join logic (PR #52 / branch 51).**
  Coverage results and exported-function metadata are now joined on a
  normalized key (`.join_key`, built via `normalize_code_script_key()`)
  instead of a raw `code_script` string. This makes the join robust to
  differing path formats (e.g. version-prefixed paths like
  `data.table-1.17.0/R/foo.R`, bare filenames `foo.R` vs `R/foo.R`, and
  case/separator differences), correctly matching functions to their
  test-coverage percentages across CRAN, Bioconductor and GitHub sources.

## R CMD check results

There were no ERRORs, WARNINGs.

There was 1 NOTE: the standard CRAN incoming feasibility note for a new
version. `test.assessr` (>= 2.1.0), a newly added import, is available on CRAN.

The rationale of the `risk.assessr` package is to validate R packages. As such, it runs processes
such as `RCMD check` and `test coverage` which may generate ERRORs, NOTEs, and WARNINGs in packages.
The tests in `risk.assessr` produce the following outputs in the test process.

`risk.assessr::run_rcmdcheck` produces these:

* **NOTE message** checking CRAN incoming feasibility ...Warning in read.dcf(file.path(dir, parts[2L])) :
  cannot open compressed file 'C:/Users/edward.gillian/AppData/Local/Temp/RtmpEVc1Jb/file5d30723213de/test.package.0002.Rcheck/00_pkg_src/test.package.0002/LICENSE', probable reason 'No such file or directory'

* **Cause**: This note occurs due to a missing LICENSE file in the test package.
  
* **NOTE message** checking CRAN incoming feasibility ... [11s] NOTE
Maintainer: 'Jane Doe <jane@example.com>'
New submission

* **Cause**: This note occurs due to a new submission for CRAN incoming feasibility in the test package.
  
* **ERROR message**  Running 'testthat.R'
 ERROR
Running the tests in 'tests/testthat.R' failed.
Last 13 lines of output:
  > library(test.package.0003)
  > 
  > test_check("test.package.0003")
  [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]
  
  ══ Failed tests ════════════════════════════════════════════════════════════════
  ── Failure ('test-myscript.R:2:3'): this works ─────────────────────────────────
  myfunction(1) (`actual`) not equal to 3 (`expected`).
  
    `actual`: 2
  `expected`: 3
  
  [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]
  Error: Test failures
  Execution halted

* **Cause**: This error occurs due to a test failure in the test package.

`risk.assessr::get_bioconductor_data` produces these:

* **ERROR message**  
Checking Bioconductor version: 3.17
Checking Bioconductor version: 3.18
Checking Bioconductor version: 3.19
Checking Bioconductor version: 3.17
Skipping Bioconductor version 3.17 due to error: Simulated error
Checking Bioconductor version: 3.18
Skipping Bioconductor version 3.18 due to error: Simulated error
Checking Bioconductor version: 3.19
Skipping Bioconductor version 3.19 due to error: Simulated error

* **Cause**: This error is simulated error to skip Bioconductor versions.

`risk.assessr::get_github_data` produces these:

* **ERROR message** 
Failed to fetch repository details:  Mocked API call failure 

* **Cause**: This error is simulated API call failure.

* **ERROR message** 
Failed to fetch commits:  Mocked commits API failure 

* **Cause**: This error is simulated commits API failure.

* **ERROR message** 
Failed to fetch repository details:  Simulated API failure 

* **Cause**: This error is simulated repository details API failure.

`risk.assessr::get_package_host_info` produces these:

* **ERROR message** 
Failed to fetch repository details:  Simulated API failure 

* **Cause**: This error is simulated repository details API failure.

`risk.assessr::install_package_local` produces these:

* **message** 
installing mock_package locally
mock_package installed locally
mock_package installed locally
installing non_existent_directory locally
No such file or directory: non_existent_directory

* **Cause**: This message is simulating failure when there is no local directory for installation.

`risk.assessr::run_coverage` produces these:

* **NOTE message** 
code coverage for test.package.0005 successful
R coverage for test.package.0005 had notes: no testable functions found
running code coverage for file4c446b4972f

* **Cause**: The test package had no testable functions.


`risk.assessr::run_coverage` produces these:

* **ERROR message** 
code coverage for file4c446b4972f unsuccessful
R coverage for file4c446b4972f failed. Read in the covr output to see what went wrong: 

* **Cause**: Code coverage failed as the test package had no testable functions.

`risk.assessr::unpack_tarball` produces these:

* **message** 
unpacking empty.tar.gz locally
not able to unpack empty.tar.gz locally

* **Cause**: This test is testing if the code can handle an empty tar file.

## skipped tests on Windows and CRAN

* **Cause**: 
* covr runs in a subprocess on Windows; mocking is not reliable under
  devtools::test() (4): test-assess_pkg.R:82:5,
  test-risk_assess_pkg.R:31:3, test-risk_assess_pkg.R:202:3,
  test-risk_assess_pkg.R:232:3
* covr runs in a subprocess on Windows; mocking is not reliable under
  devtools::test(). (2): test-assess_pkg.R:522:3, test-assess_pkg.R:644:3
* covr runs in subprocess on Windows; not reliable under devtools::test()
  (2): test-risk_assess_pkg.R:287:3, test-risk_assess_pkg.R:313:3
* file.choose mocking not reliable on Windows under devtools::test() (1):
  test-risk_assess_pkg.R:352:3
* Skipping test because CRAN is available (1):
  test-parse_dcf_dependencies.R:140:3
  
## dontrun example

These functions are set as `/dontrun` as they require an API call or web request
or the user is allowed to choose a local input path or local output path:

- assess_pkg_r_package
- fetch_bioconductor_releases
- parse_bioconductor_releases
- parse_html_version
- fetch_bioconductor_package_info
- get_bioconductor_package_url
- get_github_data
- get_internal_package_url
- check_cran_package
- parse_package_info
- get_versions
- check_and_fetch_cran_package
- get_cran_package_url
- get_host_package
- contains_vignette_folder
- modify_description_file
- risk_assess_pkg_lock_files
- risk_assess_package
- set_up_pkg
- generate_html_report
- install_package_local
- dependsOnPkgs

Internal function with examples are also set as `/dontrun`


## Additional comments
* I have ensured that the package passes all checks on different platforms.
* The package has been tested with the latest versions of its dependencies.
* I have verified that the package works correctly with the latest version of R.
* I have included a NEWS.md file to document the changes in this version.

Thank you for considering my submission.
