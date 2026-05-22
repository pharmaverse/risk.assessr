# Run R CMD CHECK

Run R CMD CHECK

## Usage

``` r
run_rcmdcheck(pkg_source_path, rcmdcheck_args)
```

## Arguments

- pkg_source_path:

  directory path to R project

- rcmdcheck_args:

  list of arguments to pass to \`rcmdcheck::rcmdcheck\`

## Details

rcmdcheck takes either a tarball or an installation directory.

The basename of \`pkg_source_path\` should be the package name and
version pasted together

The returned score is calculated via a weighted sum of notes (0.10),
warnings (0.25), and errors (1.0). It has a maximum score of 1
(indicating no errors, notes or warnings) and a minimum score of 0
(equal to 1 error, 4 warnings, or 10 notes). This scoring methodology is
expanded from \[riskmetric::metric_score.pkg_metric_r_cmd_check()\] by
including forbidden notes,
