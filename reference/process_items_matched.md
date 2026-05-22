# process items matched

create a df with functions that match exported functions from a
suggested package

## Usage

``` r
process_items_matched(items_matched, suggested_exp_func)
```

## Arguments

- items_matched:

  \- exported functions match the suggested package function

- suggested_exp_func:

  \- exported functions from a suggested package

## Details

This function extracts all the functions from the function body and
filters them to keep only function calls It also extracts all the valid
function names, matches with the source package and writes a message
