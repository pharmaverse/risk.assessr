# Write the risk assessment summary report

Renders the package risk assessment report (\`summary.Rmd\`) to a chosen
format and writes it to disk. The output file path can be inferred or
explicitly set. You can specify the output format directly via
\`output_format\` or let it be inferred from the extension of
\`output_file\`. If \`output_dir\` is not provided, the current working
directory is used.

## Usage

``` r
write_summary_report(
  results,
  output_file = NULL,
  output_format = NULL,
  output_dir = NULL
)
```

## Arguments

- results:

  A results object containing the risk assessment results. It is
  expected to include \`results\$results\$pkg_name\` and
  \`results\$results\$pkg_version\`, which are used to construct default
  file names and report parameters.

- output_file:

  \`character(1)\` or \`NULL\`. The output file path \*\*or\*\* a
  directory. - If \`NULL\`, a default name is generated:
  \`"summary_report\_\<pkg_name\>\_\<pkg_version\>.html"\` in
  \`output_dir\`. - If it is a directory, the default name is composed
  inside it. - If it is a relative path, it is resolved against
  \`output_dir\`.

- output_format:

  \`character(1)\` or \`NULL\`. Explicit output format to render: one of
  \`"html"\` or \`"md"\` (case-insensitive; do \*\*not\*\* include a
  leading dot). If \`NULL\`, the format is inferred from the extension
  of \`output_file\`. Unknown values trigger a warning and default to
  HTML.

- output_dir:

  \`character(1)\` or \`NULL\`. Base directory used when \`output_file\`
  is \`NULL\` or a relative path. If \`NULL\`, defaults to the current
  working directory (\`getwd()\`), with an informational message.

## Value

(Invisibly) the absolute path to the written report file.

## Details

The function calls \[rmarkdown::render()\] on an internal template:
\`system.file("report_templates", "summary.Rmd", package =
"risk.assessr")\`.

The format mapping is: - \`"html"\` -\> \[rmarkdown::html_document()\] -
\`"md"\` -\> \[rmarkdown::md_document()\]

If \`output_format\` is provided, it takes precedence for rendering even
if \`output_file\` has a different extension; in that case the filename
is adjusted to match the format. If \`output_format\` is not provided,
the function infers the format from \`output_file\`'s extension. For
unknown extensions, it warns and rewrites the extension to \`.html\`.

## Behavior

\- If \`output_dir\` is \`NULL\`, it defaults to \`getwd()\` and a
message is printed. - If \`output_file\` is \`NULL\`, a file name is
auto-generated as \`"summary_report\_\<pkg\>\_\<version\>.html"\` inside
\`output_dir\`. - If \`output_file\` points to an existing directory (or
ends with a path separator), a file name is composed inside that
directory as \`"summary_report\_\<pkg\>\_\<version\>.html"\`. - If
\`output_file\` is a relative path, it is resolved against
\`output_dir\`. - If \`output_format\` is provided, it determines the
render format (and the \`output_file\` name is adjusted to match the
format). - If \`output_format\` is not provided, the render format is
inferred from the extension of \`output_file\`. Unknown extensions
trigger a warning and the extension is changed to \`.html\`.

## Examples

``` r
if (FALSE) { # \dontrun{
# generate assessment_results
results <- risk_assess_pkg()

# Basic usage: auto-name in the working directory (HTML)
write_summary_report(results)

# Specify output directory (auto-name inside that directory)
write_summary_report(results, output_dir = "artifacts")

# Provide an explicit filename (relative to output_dir)
write_summary_report(results, output_file = "reports/summary.html")

# Provide a directory as output_file: auto-name inside that directory
write_summary_report(results, output_file = "reports/")

# Render to Markdown explicitly
write_summary_report(results, output_format = "md")

# Let the extension drive the format (md)
write_summary_report(results, output_file = "reports/summary.md")

# Case-insensitive formats work; avoid leading dots (".md" is not valid)
write_summary_report(results, output_format = "MD")
} # }
```
