# here package

    Code
      print_tree(here, show_version = TRUE)
    Output
      ├── version
      └── rprojroot (v2.0.4)

# here package - no versions

    Code
      print_tree(here, show_version = FALSE)
    Output
      ├── version
      └── rprojroot

# stringr package

    Code
      print_tree(stringr, show_version = TRUE)
    Output
      ├── version
      ├── cli (v3.6.2)
      │   └── utils (base)
      ├── glue (v1.7.0)
      │   └── methods (base)
      ├── lifecycle (v1.0.4)
      │   ├── cli (v3.6.2)
      │   │   └── utils (base)
      │   ├── glue (v1.7.0)
      │   │   └── methods (base)
      │   └── rlang (v1.1.3)
      │       └── utils (base)
      ├── magrittr (v2.0.3)
      ├── rlang (v1.1.3)
      │   └── utils (base)
      ├── stringi (v1.8.3)
      │   ├── tools (base)
      │   ├── utils (base)
      │   └── stats (base)
      └── vctrs (v0.6.5)
          ├── cli (v3.6.2)
          │   └── utils (base)
          ├── glue (v1.7.0)
          │   └── methods (base)
          ├── lifecycle (v1.0.4)
          └── rlang (v1.1.3)
              └── utils (base)

# stringr package - no versions

    Code
      print_tree(stringr, show_version = FALSE)
    Output
      ├── version
      ├── cli
      │   └── utils (base)
      ├── glue
      │   └── methods (base)
      ├── lifecycle
      │   ├── cli
      │   │   └── utils (base)
      │   ├── glue
      │   │   └── methods (base)
      │   └── rlang
      │       └── utils (base)
      ├── magrittr
      ├── rlang
      │   └── utils (base)
      ├── stringi
      │   ├── tools (base)
      │   ├── utils (base)
      │   └── stats (base)
      └── vctrs
          ├── cli
          │   └── utils (base)
          ├── glue
          │   └── methods (base)
          ├── lifecycle
          └── rlang
              └── utils (base)

