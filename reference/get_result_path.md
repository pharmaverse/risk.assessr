# Assign output file path for various outputs during scorecard rendering

Assign output file path for various outputs during scorecard rendering

## Usage

``` r
get_result_path(
  out_dir,
  ext = c("check.rds", "covr.rds", "tm_doc.rds", "tm_doc.xlsx")
)
```

## Arguments

- out_dir:

  output directory for saving results

- ext:

  file name and extension

## Details

The basename of \`out_dir\` should be the package name and version
pasted together
