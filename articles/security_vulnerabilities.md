# Security vulnerabilities

## Introduction

The security vulnerabilities feature checks for known, publicly
disclosed vulnerabilities in the R package being assessed. It is
accessed through:

- [`generate_security_vulnerabilities()`](https://pharmaverse.github.io/risk.assessr/reference/generate_security_vulnerabilities.md)
  — the exported stand-alone function that retrieves advisories for a
  package.
- [`get_security_vulnerabilities()`](https://pharmaverse.github.io/risk.assessr/reference/get_security_vulnerabilities.md)
  — the exported function that retrieves advisories for a package.

This latter function is run automatically as part of a full assessment
via
[`risk_assess_pkg()`](https://pharmaverse.github.io/risk.assessr/reference/risk_assess_pkg.md)
/
[`assess_pkg()`](https://pharmaverse.github.io/risk.assessr/reference/assess_pkg.md).

------------------------------------------------------------------------

## Where the data comes from

Advisories are retrieved from the **Open Source Vulnerabilities (OSV)**
database (<https://osv.dev>) using a `POST` request to the query
endpoint `https://api.osv.dev/v1/query`. For R packages, OSV serves
advisories from the [R Consortium
r-advisory-database](https://github.com/RConsortium/r-advisory-database),
which carry `RSEC-*` identifiers.

The package is queried by name only within the `"CRAN"` ecosystem. All
advisories for the package are fetched, then filtered locally against
the installed version. Querying by name (rather than name + version)
avoids missing range-based advisories that a version-scoped OSV query
can silently omit.

------------------------------------------------------------------------

## OSV data base - Defined ecosystems

The functions can query the defined ecosystemsin `OSV`.

The defined ecosystems are:

| Ecosystem | Description |
|:---|:---|
| **AlmaLinux** | AlmaLinux package ecosystem; the name is the name of the source package. The ecosystem string might optionally have a `:<RELEASE>` suffix to scope the package to a particular AlmaLinux release. `<RELEASE>` is a numeric version. |
| **Alpaquita** | BellSoft Alpaquita Linux package ecosystem; the name is the name of the source package. The ecosystem string has a `:<RELEASE>` suffix to scope the package to a particular Alpaquita Linux release. `<RELEASE>` is the id of the particular Alpaquita Linux release. Examples: `Alpaquita:23`, `Alpaquita:stream`. |
| **Alpine** | The Alpine package ecosystem; the name is the name of the source package. The ecosystem string must have a `:v<RELEASE-NUMBER>` suffix to scope the package to a particular Alpine release branch (the v prefix is required). E.g. `v3.16`. |
| **Android** | The Android ecosystem. Android organizes code using [repo tool](https://gerrit.googlesource.com/git-repo/+/HEAD/README.md), which manages multiple git projects under one or more remote git servers, where each project is identified by its name in [repo configuration](https://gerrit.googlesource.com/git-repo/+/HEAD/docs/manifest-format.md#Element-project) (e.g. `platform/frameworks/base`). The name field should contain the name of that affected git project/submodule. One exception is when the project contains the Linux kernel source code, in which case name field will be `:linux_kernel:`, followed by an optional SoC vendor name e.g. `:linux_kernel:Qualcomm`. The list of recognized SoC vendors is listed in the [Appendix](https://ossf.github.io/osv-schema/#android-soc-vendors). |
| **Azure Linux** | The Azure Linux package ecosystem; the name is the name of the source package. The ecosystem string has a `:<RELEASE>` suffix to scope the package to a particular Azure Linux release. `<RELEASE>` is a numeric version. |
| **BellSoft Hardened Containers** | BellSoft Hardened Containers package ecosystem; the name is the name of the source package. The ecosystem string has a `:<RELEASE>` suffix to scope the package to a particular Hardened Containers release. `<RELEASE>` is the id of the particular Hardened Containers release. Examples: `BellSoft Hardened Containers:23`, `BellSoft Hardened Containers:stream`. |
| **Bioconductor** | The biological R package ecosystem. The name is an R package name. |
| **Bitnami** | Bitnami package ecosystem; the name is the name of the affected component. |
| **Chainguard** | The Chainguard package ecosystem; the name is the name of the package. |
| **CleanStart** | The CleanStart package ecosystem; the name is the name of the package. |
| **ConanCenter** | The ConanCenter ecosystem for C and C++; the name field is a Conan package name. |
| **CRAN** | The R package ecosystem. The name is an R package name. |
| **crates.io** | The crates.io ecosystem for Rust; the name field is a crate name. |
| **Debian** | The Debian package ecosystem; the name is the name of the source package. The ecosystem string might optionally have a `:<RELEASE>` suffix to scope the package to a particular Debian release. `<RELEASE>` is a numeric version specified in the [Debian distro-info-data](https://debian.pages.debian.net/distro-info-data/debian.csv). For example, the ecosystem string “Debian:7” refers to the Debian 7 (wheezy) release. For versions without a numeric version, use the string in the series column of the distro-info-data CSV, e.g. “Debian:sid”. |
| **Docker Hardened Images** | The Docker Hardened Images package ecosystem; the name is the name of the package. |
| **Echo** | The Echo package ecosystem; the name is the name of the source package. |
| **FreeBSD** | The FreeBSD ecosystem consists of three main components: the base system, kernel, and ports. For ports, the name refers to the name of a package managed by `pkg(8)`, which is the FreeBSD package manager. Ecosystem strings can include `:ports`, indicating that an issue pertains to ports (e.g., ‘FreeBSD:ports’). Base system issues should be categorized under `:base`. The `ranges[].events` versions correspond to specific FreeBSD releases, such as ‘FreeBSD:base:14.3’. Kernel-related issues are denoted by `:kernel`, with examples like ‘FreeBSD:kernel’. Every namespace can have optional `:<RELEASE>` segment at last, which can be used to specify that an issue applies only to a particular FreeBSD release like. |
| **GHC** | The Haskell compiler ecosystem. The name field is the name of a component of the GHC compiler ecosystem (e.g., `compiler`, `GHCI`, `RTS`). |
| **GitHub Actions** | The GitHub Actions ecosystem; the name field is the action’s repository name with owner e.g. `{owner}/{repo}`. |
| **Go** | The Go ecosystem; the name field is a Go module path. |
| **Hackage** | The Haskell package ecosystem. The name field is a Haskell package name as published on Hackage. |
| **Hex** | The package manager for the Erlang ecosystem; the name is a Hex package name. |
| **Homebrew** | The Homebrew package manager for macOS and Linux; the name is the formula name (e.g. `openssl@3`). Casks are not currently in scope. Without a `:<tap>` suffix the formula is assumed to come from the default `homebrew/core` tap. A version is the formula version as reported by `brew info` with an `_N` suffix when the formula revision is nonzero (e.g. `1.81.6_6`), matching the version component of a `pkg:brew` purl. The ECOSYSTEM version ordering is Homebrew’s PkgVersion comparison: the version segment compared by Homebrew’s Version class, then the numeric revision suffix. The database uses introduced and fixed boundaries. |
| **Julia** | The Julia Programming Language ecosystem; the name is a registered package in the General registry. |
| **Kubernetes** | The Kubernetes ecosystem; name is the Go module name associated with the relevant Kubernetes component (e.g. `k8s.io/apiserver`) |
| **Linux** | The Linux kernel. The only supported name is Kernel. |
| **Mageia** | The Mageia Linux package ecosystem; the name is the name of the source package. The ecosystem string must have a `:<RELEASE-NUMBER>` suffix to scope the package to a particular Mageia release. Eg `Mageia:9`. |
| **Maven** | The Maven Java package ecosystem. The name field is a Maven package name in the format `groupId:artifactId`. The ecosystem string might optionally have a `:<REMOTE-REPO-URL>` suffix to denote the remote repository URL that best represents the source of truth for this package, without a trailing slash (e.g. `Maven:https://maven.google.com`). If this is omitted, this is assumed to be the Maven Central repository (`https://repo.maven.apache.org/maven2`). |
| **MinimOS** | The MinimOS package ecosystem; the name is the name of the package. |
| **npm** | The NPM ecosystem; the name field is an NPM package name. |
| **NuGet** | The NuGet package ecosystem. The name field is a NuGet package name. |
| **opam** | The OCaml package manager ecosystem. The name field is an opam package name. |
| **openEuler** | The openEuler ecosystem; source RPM name field, with `<RELEASE>` (`YY.MM`) LTS suffix details, scope notes, and `ecosystem_specific` package info. |
| **openSUSE** | The openSUSE ecosystem; `:<RELEASE>` suffix matching `PRETTY_NAME`, source RPM with purl, binary arrays, and RPM version ordering. |
| **OSS-Fuzz** | For reports from the OSS-Fuzz project that have no more appropriate ecosystem; the name field is the name assigned by the OSS-Fuzz project, as recorded in the submitted fuzzing configuration. |
| **Packagist** | The PHP package manager ecosystem; the name is a package name. The ecosystem string might optionally have a `:<REMOTE-REPO-URL>` suffix to denote the remote repository URL that best represents the source of truth for this package, without a trailing slash (e.g. `Packagist:https://packages.drupal.org/8`). If this is omitted, this is assumed to be the Packagist repository (`https://packagist.org`). |
| **Photon OS** | The Photon OS package ecosystem; the name is the name of the RPM package. The ecosystem string must have a `:<RELEASE-NUMBER>` suffix to scope the package to a particular Photon OS release. Eg `Photon OS:3.0`. |
| **Pub** | The package manager for the Dart ecosystem; the name field is a Dart package name. |
| **PyPI** | The Python PyPI ecosystem; the name field is a normalized PyPI package name. |
| **Red Hat** | The Red Hat package ecosystem; the name field is the name of a binary or source RPM. The ecosystem string has a `:<CPE>` suffix to scope the RPM to a specific Red Hat product stream. `<CPE>` is a translation of a Red Hat [Common Platform Enumerations](https://cpe.mitre.org/) (CPE) with the `cpe/:[oa]:(redhat):` prefix removed (for example, `Red Hat:rhel_aus:8.4::appstream` translates to `cpe:/a:redhat:rhel_aus:8.4::appstream`). Red Hat ecosystem identifiers can be used to identify vulnerable RPMs installed on a Red Hat system as explained [here](https://www.redhat.com/en/blog/how-accurately-match-oval-security-data-installed-rpms). |
| **Rocky Linux** | The Rocky Linux package ecosystem; the name is the name of the source package. The ecosystem string might optionally have a `:<RELEASE>` suffix to scope the package to a particular Rocky Linux release. `<RELEASE>` is a numeric version. |
| **Root** | The Root container security ecosystem. Root provides patched container images across multiple base distributions. The ecosystem uses hierarchical variants: `Root:{BaseDistro}:{Version}` for OS packages (e.g., `Root:Alpine:3.18`, `Root:Debian:12`) and `Root:{PackageManager}` for application packages (e.g., `Root:PyPI`, `Root:npm`). Package names use Root-specific prefixes (`root-{package}` for most, `@root/{package}` for npm). |
| **RubyGems** | The RubyGems ecosystem; the name field is a gem name. |
| **SUSE** | The SUSE ecosystem; The ecosystem string has a `:<RELEASE>` suffix representing the marketing name of the SUSE product. `<RELEASE>` matches the value in the `/etc/os-release` `PRETTY_NAME` field. The name field is the name of the source RPM and accompanied by a purl. There is a `ecosystem_specific` specific array binaries of the associated RPM binary packages in this specific SUSE product. The ECOSYSTEM version ordering is the RPM versioncompare ordering, and the database uses the introduced and fixed boundaries. |
| **SwiftURL** | The Swift Package Manager ecosystem. The name is a Git URL to the source of the package. Versions are Git tags that conform to [SemVer 2.0](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html#version). |
| **TuxCare** | TuxCare package ecosystem; the name is the name of the source package. The ecosystem string might optionally have a `:<RELEASE>` suffix to scope the package to a particular TuxCare release. `<RELEASE>` is a numeric version. |
| **Ubuntu** | The Ubuntu package ecosystem; the name field is the name of the source package. The ecosystem string has a `:<RELEASE>` suffix to scope the package to a particular Ubuntu release. `<RELEASE>` is a numeric (“YY.MM”) version as specified in Ubuntu Releases, with a mandatory `:LTS` suffix if the release is marked as LTS. The release version may also be prefixed with `:Pro:` to denote Ubuntu Pro (aka Expanded Security Maintenance (ESM)) updates. For example, the ecosystem string “Ubuntu:22.04:LTS” refers to Ubuntu 22.04 LTS (jammy), while “Ubuntu:Pro:18.04:LTS” refers to fixes that landed in Ubuntu 18.04 LTS (bionic) under Ubuntu Pro/ESM. |
| **vcpkg** | The vcpkg ecosystem for Microsoft’s C/C++ package manager; the name is the vcpkg port name (e.g. `bzip2`, `ffmpeg`). The ecosystem string has no release suffix. A version is the upstream port version; the integer `port-version` (incremented when the port packaging changes) is carried in the purl `port_version` qualifier. The default registry is `microsoft/vcpkg`; non-default registries are denoted by the purl `repository_url` / `repository_revision` qualifiers. |
| **VSCode** | The Visual Studio Code extensions ecosystem; the name is the `<publisher>.<name>` string which uniquely identifies a package. This identifier is composed from the Publisher and Id attributes of the Identity element in the package’s `.vsixmanifest` file. It also corresponds to the `itemName` parameter of the package as found on the \[Visual Studio Marketplace for VS Code\] link - `https://marketplace.visualstudio.com/vscode` extensions page, or the namespace and name fields of the [OpenVSX](https://open-vsx.org/) API response for the target package. The ecosystem string might optionally have a `:<REMOTE-REPO-URL>` suffix to denote the remote repository URL that best represents the source of truth for this package, without a trailing slash (e.g. `VSCode:https://open-vsx.org`). If this is omitted, this is assumed to be the Visual Studio Marketplace for \[VSCode\] link - `https://marketplace.visualstudio.com/vscode`. |

------------------------------------------------------------------------

## Load the package

``` r

library(risk.assessr)
```

------------------------------------------------------------------------

## Retrieving vulnerabilities directly

``` r

vulns <- get_security_vulnerabilities("commonmark", "1.7")
vulns
```

The function returns a data frame with one row per advisory and the
following columns:

- `id` — advisory identifier (e.g. `RSEC-2023-6`)
- `summary` — short vulnerability type
- `details` — full description
- `introduced` — version the issue was introduced
- `fixed` — version the issue was fixed
- `modified`, `published` — advisory timestamps

If no advisories apply, a zero-row data frame with the same columns is
returned. Omitting the version returns every advisory known for the
package.

------------------------------------------------------------------------

## Stand-alone assessment

``` r

results <- generate_security_vulnerabilities(
   "commonmark",
   pkg_ver = "1.7"
)

print(results)
```

The function returns a data frame with one row per advisory plus package
name and version.

## Within a full assessment

When you assess a package, the vulnerabilities are stored in the results
object:

``` r

result <- risk_assess_pkg(package = "commonmark", version = "1.7")
result$results$vulnerabilities
```

------------------------------------------------------------------------

## How results are reported

**Summary report** — vulnerabilities appear as a single metric,
“Security Vulnerabilities”, showing the count of advisories found. Any
count of one or more is scored **High** risk; zero is scored **Low**.
This contributes to the overall recommendation alongside the other risk
metrics.

**HTML report** — when advisories are found, the report renders a
red-headed, searchable table listing every advisory (`ID`, `Summary`,
`Details`, `Introduced`, `Fixed`, `Modified`, `Published`). When none
are found, a green “No security vulnerabilities” banner is shown
instead.

------------------------------------------------------------------------

## Limitations

- Only the `"CRAN"` ecosystem is queried; Bioconductor is not
  auto-detected.
- The feature requires network access to the OSV API.
- API failures return an empty result, so absence of rows is not by
  itself a guarantee that a package is free of vulnerabilities — check
  the console messages.
- Vulnerability scoring is not configurable through
  `risk-definition.json` at the moment.
