# Generate Security Vulnerabilities Section

Generates the security vulnerabilities section for the HTML report. When
one or more known vulnerabilities are present (the \`vulnerabilities\`
data frame in the assessment results has at least one row) a
display-ready data frame is returned. Otherwise a single-row data frame
carrying the message "No security vulnerabilities" is returned so the
report can clearly state that none were found.

## Usage

``` r
generate_vulnerabilities_section(assessment_results)
```

## Arguments

- assessment_results:

  \- input data

## Value

A data frame. When vulnerabilities are present it has the columns
\`ID\`, \`Summary\`, \`Details\`, \`Introduced\`, \`Fixed\`,
\`Modified\`, and \`Published\`. When none are present it has a single
\`Message\` column.
